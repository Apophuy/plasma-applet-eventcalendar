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

try:
    from icalendar import Calendar
except ImportError:
    print("The Python 'icalendar' module is required.", file=sys.stderr)
    raise SystemExit(3)


MAX_CALENDAR_BYTES = 10 * 1024 * 1024
REQUEST_TIMEOUT_SECONDS = 20


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


def event_id(event, start, end):
    uid = str(event.get("UID", ""))
    value = "\0".join((uid, start.isoformat(), end.isoformat()))
    return "ics_" + hashlib.sha256(value.encode("utf-8")).hexdigest()


def events_to_json(event_list, indent=4):
    items = []
    for event in event_list:
        start = event.decoded("DTSTART")
        end = event_end(event, start)
        item = {
            "kind": "calendar#event",
            "etag": '\"0123456789012345\"',
            "iCalUID": str(event.get("UID", "")),
            "id": event_id(event, start, end),
            "status": str(event.get("STATUS", "confirmed")).lower(),
            "htmlLink": str(event.get("URL", "")),
            "summary": str(event.get("SUMMARY", "")),
            "start": date_to_json(start),
            "end": date_to_json(end),
        }
        if "CREATED" in event:
            item["created"] = event.decoded("CREATED").isoformat()
        if "LAST-MODIFIED" in event:
            item["updated"] = event.decoded("LAST-MODIFIED").isoformat()
        if "LOCATION" in event:
            item["location"] = str(event.get("LOCATION"))
        if "DESCRIPTION" in event:
            item["description"] = str(event.get("DESCRIPTION"))
        items.append(item)
    return json.dumps({"items": items}, indent=indent, ensure_ascii=False)


def comparable_datetime(value):
    if isinstance(value, datetime.datetime):
        result = value
    else:
        result = datetime.datetime.combine(value, datetime.time.min)
    return result.astimezone(datetime.timezone.utc).replace(tzinfo=None)


def event_within(event, start_time, end_time_exclusive):
    event_start_value = event.decoded("DTSTART")
    event_end_value = event_end(event, event_start_value)
    event_start = comparable_datetime(event_start_value)
    event_end_time = comparable_datetime(event_end_value)
    start = comparable_datetime(start_time)
    end = comparable_datetime(end_time_exclusive)
    return event_start < end and event_end_time > start


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
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            data = response.read(MAX_CALENDAR_BYTES + 1)
        if len(data) > MAX_CALENDAR_BYTES:
            raise ValueError("The iCalendar file is larger than 10 MiB.")
        self.calendar = Calendar.from_ical(data)

    @property
    def events(self):
        return self.calendar.walk("vevent")

    def query(self, start_time, end_time):
        end_time_exclusive = end_time + datetime.timedelta(days=1)
        return (
            event
            for event in self.events
            if event_within(event, start_time, end_time_exclusive)
        )


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
    except (KeyError, OSError, TypeError, ValueError, urllib.error.URLError) as error:
        print("Could not read iCalendar data: {}".format(error), file=sys.stderr)
        return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
