#!/usr/bin/env python3

import argparse
import datetime
import hashlib
import json
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from dataclasses import dataclass

try:
    from icalendar import Calendar
    from dateutil.rrule import rruleset, rrulestr
except ImportError:
    print("The Python 'icalendar' module is required.", file=sys.stderr)
    raise SystemExit(3)


MAX_CALENDAR_BYTES = 10 * 1024 * 1024
MAX_OCCURRENCES_PER_QUERY = 10000
REQUEST_TIMEOUT_SECONDS = 20


@dataclass(frozen=True)
class EventOccurrence:
    event: object
    start: object
    end: object
    recurrence_id: object = None
    fallback_event: object = None


def date_to_json(value):
    if isinstance(value, datetime.datetime):
        return {"dateTime": value.isoformat()}
    return {"date": value.isoformat()}


def event_end(event, start):
    if "DTEND" in event:
        return event.decoded("DTEND")
    if "DURATION" in event:
        return start + event.decoded("DURATION")
    if isinstance(start, datetime.datetime):
        return start
    return start + datetime.timedelta(days=1)


def event_duration(event):
    start = event.decoded("DTSTART")
    return event_end(event, start) - start


def property_event(event, fallback_event, name):
    if name in event:
        return event
    if fallback_event is not None and name in fallback_event:
        return fallback_event
    return None


def property_text(event, fallback_event, name, default=""):
    source = property_event(event, fallback_event, name)
    return str(source.get(name)) if source is not None else default


def decoded_property(event, fallback_event, name):
    source = property_event(event, fallback_event, name)
    return source.decoded(name) if source is not None else None


def event_id(occurrence):
    uid = property_text(
        occurrence.event, occurrence.fallback_event, "UID"
    )
    if occurrence.recurrence_id is None:
        parts = (uid, occurrence.start.isoformat(), occurrence.end.isoformat())
    else:
        parts = (uid, "recurrence", occurrence.recurrence_id.isoformat())
    value = "\0".join(parts)
    return "ics_" + hashlib.sha256(value.encode("utf-8")).hexdigest()


def occurrence_to_json(occurrence):
    event = occurrence.event
    fallback_event = occurrence.fallback_event
    item = {
        "kind": "calendar#event",
        "etag": '\"0123456789012345\"',
        "iCalUID": property_text(event, fallback_event, "UID"),
        "id": event_id(occurrence),
        "status": property_text(
            event, fallback_event, "STATUS", "confirmed"
        ).lower(),
        "htmlLink": property_text(event, fallback_event, "URL"),
        "summary": property_text(event, fallback_event, "SUMMARY"),
        "start": date_to_json(occurrence.start),
        "end": date_to_json(occurrence.end),
    }
    created = decoded_property(event, fallback_event, "CREATED")
    updated = decoded_property(event, fallback_event, "LAST-MODIFIED")
    if created is not None:
        item["created"] = created.isoformat()
    if updated is not None:
        item["updated"] = updated.isoformat()
    for name, output_name in (
        ("LOCATION", "location"),
        ("DESCRIPTION", "description"),
    ):
        source = property_event(event, fallback_event, name)
        if source is not None:
            item[output_name] = str(source.get(name))
    return item


def events_to_json(event_list, indent=4):
    items = [occurrence_to_json(occurrence) for occurrence in event_list]
    return json.dumps({"items": items}, indent=indent, ensure_ascii=False)


def comparable_datetime(value):
    if isinstance(value, datetime.datetime):
        result = value
    else:
        result = datetime.datetime.combine(value, datetime.time.min)
    return result.astimezone(datetime.timezone.utc).replace(tzinfo=None)


def values_within(event_start, event_end, start_time, end_time_exclusive):
    start = comparable_datetime(start_time)
    end = comparable_datetime(end_time_exclusive)
    return (
        comparable_datetime(event_start) < end
        and comparable_datetime(event_end) > start
    )


def event_within(event, start_time, end_time_exclusive):
    event_start_value = event.decoded("DTSTART")
    event_end_value = event_end(event, event_start_value)
    return values_within(
        event_start_value,
        event_end_value,
        start_time,
        end_time_exclusive,
    )


def recurrence_key(value):
    if isinstance(value, datetime.datetime):
        if value.tzinfo is not None and value.utcoffset() is not None:
            value = value.astimezone(datetime.timezone.utc)
        return ("datetime", value.replace(tzinfo=None).isoformat())
    return ("date", value.isoformat())


def properties(event, name):
    value = event.get(name)
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def recurrence_values(event, name):
    for value_list in properties(event, name):
        for value in value_list.dts:
            yield value.dt


def recurrence_datetime(value, template):
    if isinstance(value, datetime.datetime):
        result = value
    else:
        result = datetime.datetime.combine(value, datetime.time.min)

    template_is_aware = (
        isinstance(template, datetime.datetime)
        and template.tzinfo is not None
        and template.utcoffset() is not None
    )
    result_is_aware = result.tzinfo is not None and result.utcoffset() is not None
    if template_is_aware and not result_is_aware:
        return result.replace(tzinfo=template.tzinfo)
    if not template_is_aware and result_is_aware:
        return result.replace(tzinfo=None)
    return result


def recurrence_value(value, all_day):
    return value.date() if all_day else value


def query_bound(value, recurrence_start):
    if (
        isinstance(recurrence_start, datetime.datetime)
        and recurrence_start.tzinfo is not None
        and recurrence_start.utcoffset() is not None
    ):
        return value.astimezone(recurrence_start.tzinfo)
    return value.replace(tzinfo=None)


def period_parts(value):
    start, end_or_duration = value
    if isinstance(end_or_duration, datetime.timedelta):
        return start, start + end_or_duration
    return start, end_or_duration


def recurrence_set(event):
    event_start_value = event.decoded("DTSTART")
    rule_start = recurrence_datetime(event_start_value, event_start_value)
    result = rruleset()
    result.rdate(rule_start)
    period_durations = {}

    for rule in properties(event, "RRULE"):
        rule_text = rule.to_ical().decode("utf-8")
        result.rrule(rrulestr(rule_text, dtstart=rule_start))

    for value in recurrence_values(event, "RDATE"):
        if isinstance(value, tuple):
            period_start, period_end = period_parts(value)
            value = period_start
            normalized_start = recurrence_datetime(value, event_start_value)
            period_durations[
                recurrence_key(
                    recurrence_value(
                        normalized_start,
                        not isinstance(event_start_value, datetime.datetime),
                    )
                )
            ] = period_end - period_start
        result.rdate(recurrence_datetime(value, event_start_value))

    for value in recurrence_values(event, "EXDATE"):
        result.exdate(recurrence_datetime(value, event_start_value))

    return result, period_durations


def is_cancelled(event, fallback_event=None):
    return property_text(
        event, fallback_event, "STATUS", "confirmed"
    ).lower() == "cancelled"


def event_priority(event, index):
    sequence = event.get("SEQUENCE", 0)
    try:
        sequence = int(sequence)
    except (TypeError, ValueError):
        sequence = 0
    updated = decoded_property(event, None, "LAST-MODIFIED")
    updated_key = (
        comparable_datetime(updated)
        if updated is not None
        else datetime.datetime.min
    )
    return sequence, updated_key, index


def select_latest(events):
    return max(
        enumerate(events),
        key=lambda indexed: event_priority(indexed[1], indexed[0]),
    )[1]


def recurrence_id(event):
    return event.decoded("RECURRENCE-ID")


def recurrence_range(event):
    value = event.get("RECURRENCE-ID")
    return str(value.params.get("RANGE", "")).upper()


def detached_occurrence(event, master, identity):
    start = event.decoded("DTSTART")
    return EventOccurrence(
        event=event,
        start=start,
        end=event_end(event, start),
        recurrence_id=identity,
        fallback_event=master,
    )


def query_recurring_event(master, overrides, start_time, end_time_exclusive):
    master_start = master.decoded("DTSTART")
    all_day = not isinstance(master_start, datetime.datetime)
    master_duration = event_duration(master)
    rule, period_durations = recurrence_set(master)

    override_map = {}
    grouped_overrides = defaultdict(list)
    for override in overrides:
        grouped_overrides[recurrence_key(recurrence_id(override))].append(override)
    for key, candidates in grouped_overrides.items():
        override_map[key] = select_latest(candidates)

    range_overrides = []
    durations = [master_duration]
    shifts = [datetime.timedelta()]
    for override in override_map.values():
        override_duration = (
            event_duration(override)
            if "DTSTART" in override
            else master_duration
        )
        durations.append(override_duration)
        if recurrence_range(override) == "THISANDFUTURE":
            identity = recurrence_id(override)
            identity_datetime = recurrence_datetime(identity, master_start)
            override_start = recurrence_datetime(
                override.decoded("DTSTART")
                if "DTSTART" in override
                else identity,
                master_start,
            )
            shift = override_start - identity_datetime
            range_overrides.append(
                (identity_datetime, override, shift, override_duration)
            )
            shifts.append(shift)
    range_overrides.sort(key=lambda item: item[0])

    durations.extend(period_durations.values())
    maximum_duration = max(
        (duration for duration in durations if duration > datetime.timedelta()),
        default=datetime.timedelta(),
    )
    maximum_positive_shift = max(
        (shift for shift in shifts if shift > datetime.timedelta()),
        default=datetime.timedelta(),
    )
    minimum_negative_shift = min(
        (shift for shift in shifts if shift < datetime.timedelta()),
        default=datetime.timedelta(),
    )

    query_start = query_bound(start_time, master_start)
    query_end = query_bound(end_time_exclusive, master_start)
    generation_start = query_start - maximum_duration - maximum_positive_shift
    generation_end = query_end - minimum_negative_shift

    occurrences = []
    handled_overrides = set()
    generated_count = 0
    for generated_start in rule.xafter(generation_start, inc=True):
        if generated_start >= generation_end:
            break
        generated_count += 1
        if generated_count > MAX_OCCURRENCES_PER_QUERY:
            raise ValueError(
                "The recurrence produces more than {} events in the requested "
                "range.".format(MAX_OCCURRENCES_PER_QUERY)
            )

        original_start = recurrence_value(generated_start, all_day)
        key = recurrence_key(original_start)
        exact_override = override_map.get(key)
        if exact_override is not None:
            handled_overrides.add(key)
            if is_cancelled(exact_override, master):
                continue
            occurrence = detached_occurrence(
                exact_override, master, original_start
            )
        else:
            active_range = None
            for candidate in range_overrides:
                if candidate[0] <= generated_start:
                    active_range = candidate
                else:
                    break
            if active_range is not None:
                _, range_event, shift, duration = active_range
                if is_cancelled(range_event, master):
                    continue
                actual_start_datetime = generated_start + shift
                actual_start = recurrence_value(actual_start_datetime, all_day)
                occurrence = EventOccurrence(
                    event=range_event,
                    start=actual_start,
                    end=actual_start + duration,
                    recurrence_id=original_start,
                    fallback_event=master,
                )
            else:
                duration = period_durations.get(key, master_duration)
                occurrence = EventOccurrence(
                    event=master,
                    start=original_start,
                    end=original_start + duration,
                    recurrence_id=original_start,
                )

        if values_within(
            occurrence.start,
            occurrence.end,
            start_time,
            end_time_exclusive,
        ):
            occurrences.append(occurrence)

    for key, override in override_map.items():
        if key in handled_overrides or is_cancelled(override, master):
            continue
        identity = recurrence_id(override)
        occurrence = detached_occurrence(override, master, identity)
        if values_within(
            occurrence.start,
            occurrence.end,
            start_time,
            end_time_exclusive,
        ):
            occurrences.append(occurrence)

    return occurrences


def normalize_url(value):
    parsed = urllib.parse.urlparse(value)
    if not parsed.scheme:
        return pathlib.Path(value).expanduser().resolve().as_uri()
    if parsed.scheme not in ("file", "http", "https"):
        raise ValueError("Only local files and HTTP(S) URLs are supported.")
    return value


class CalendarManager:
    def __init__(self, url):
        self.url = normalize_url(url)
        self.calendar = None

    def read(self):
        request = urllib.request.Request(
            self.url,
            headers={"User-Agent": "KDE Event Calendar iCalendar reader"},
        )
        with urllib.request.urlopen(
            request, timeout=REQUEST_TIMEOUT_SECONDS
        ) as response:
            data = response.read(MAX_CALENDAR_BYTES + 1)
        if len(data) > MAX_CALENDAR_BYTES:
            raise ValueError("The iCalendar file is larger than 10 MiB.")
        self.calendar = Calendar.from_ical(data)

    @property
    def events(self):
        return self.calendar.walk("vevent")

    def query(self, start_time, end_time):
        end_time_exclusive = end_time + datetime.timedelta(days=1)
        grouped_events = defaultdict(list)
        for index, event in enumerate(self.events):
            uid = str(event.get("UID", ""))
            group_key = uid if uid else "__missing_uid_{}".format(index)
            grouped_events[group_key].append(event)

        occurrences = []
        for event_group in grouped_events.values():
            masters = [
                event for event in event_group if "RECURRENCE-ID" not in event
            ]
            overrides = [
                event for event in event_group if "RECURRENCE-ID" in event
            ]
            group_is_recurring = overrides or any(
                "RRULE" in event or "RDATE" in event for event in masters
            )

            if not group_is_recurring:
                for event in masters:
                    if event_within(event, start_time, end_time_exclusive):
                        start = event.decoded("DTSTART")
                        occurrences.append(
                            EventOccurrence(event, start, event_end(event, start))
                        )
                continue

            if not masters:
                for event in overrides:
                    if is_cancelled(event):
                        continue
                    identity = recurrence_id(event)
                    occurrence = detached_occurrence(event, None, identity)
                    if values_within(
                        occurrence.start,
                        occurrence.end,
                        start_time,
                        end_time_exclusive,
                    ):
                        occurrences.append(occurrence)
                continue

            master = select_latest(masters)
            if not is_cancelled(master):
                occurrences.extend(
                    query_recurring_event(
                        master, overrides, start_time, end_time_exclusive
                    )
                )

        occurrences.sort(
            key=lambda occurrence: (
                comparable_datetime(occurrence.start),
                property_text(
                    occurrence.event, occurrence.fallback_event, "UID"
                ),
                event_id(occurrence),
            )
        )
        return occurrences


def parse_date(value):
    try:
        return datetime.datetime.strptime(value, "%Y-%m-%d")
    except ValueError as error:
        raise argparse.ArgumentTypeError(
            "Not a valid date: '{}'".format(value)
        ) from error


def main():
    parser = argparse.ArgumentParser(description="Read iCalendar events as JSON")
    parser.add_argument("--url", required=True, help="Local path or HTTP(S) .ics URL")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    query_parser = subparsers.add_parser("query")
    query_parser.add_argument("startTime", type=parse_date)
    query_parser.add_argument("endTime", type=parse_date)

    args = parser.parse_args()
    manager = CalendarManager(args.url)
    try:
        manager.read()
        print(events_to_json(manager.query(args.startTime, args.endTime)))
    except (
        KeyError,
        OSError,
        OverflowError,
        TypeError,
        ValueError,
        urllib.error.URLError,
    ) as error:
        print("Could not read iCalendar data: {}".format(error), file=sys.stderr)
        return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
