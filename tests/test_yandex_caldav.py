import importlib.util
import datetime
import pathlib
import sys
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "package/contents/scripts/yandex_caldav.py"
sys.path.insert(0, str(MODULE_PATH.parent))
SPEC = importlib.util.spec_from_file_location("yandex_caldav", MODULE_PATH)
CALDAV = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CALDAV)
HAS_ICALENDAR = importlib.util.find_spec("icalendar") is not None


HOME_RESPONSE = b"""<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:response><d:propstat><d:prop><c:calendar-home-set>
    <d:href>/calendars/test@example.com/</d:href>
  </c:calendar-home-set></d:prop></d:propstat></d:response>
</d:multistatus>
"""


CALENDAR_RESPONSE = b"""<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:a="http://apple.com/ns/ical/">
  <d:response>
    <d:href>/calendars/test@example.com/one/</d:href>
    <d:propstat><d:prop>
      <d:displayname>Personal</d:displayname>
      <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
      <a:calendar-color>#123456ff</a:calendar-color>
    </d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/calendars/test@example.com/two/</d:href>
    <d:propstat><d:prop>
      <d:displayname>Work</d:displayname>
      <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>
"""


EVENT_RESPONSE = b"""<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:response>
    <d:href>/calendars/test@example.com/one/event.ics</d:href>
    <d:propstat><d:prop>
      <d:getetag>event-etag</d:getetag>
      <c:calendar-data><![CDATA[BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:event-1
DTSTART:20261006T100000Z
DTEND:20261006T110000Z
SUMMARY:Yandex test event
END:VEVENT
END:VCALENDAR
]]></c:calendar-data>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>
"""


class DiscoveryTests(unittest.TestCase):
    def test_rejects_caldav_urls_outside_yandex(self):
        with self.assertRaises(CALDAV.CalDavError):
            CALDAV.validate_caldav_url("https://example.com/calendar/")

    def test_discovers_multiple_calendars_with_stable_local_ids(self):
        with mock.patch.object(
            CALDAV, "request", side_effect=[HOME_RESPONSE, CALENDAR_RESPONSE]
        ) as request:
            calendars = CALDAV.discover(
                "test@example.com", "application-password", "account-1"
            )

        self.assertEqual([item["summary"] for item in calendars], ["Personal", "Work"])
        self.assertEqual(calendars[0]["backgroundColor"], "#123456")
        self.assertTrue(calendars[1]["backgroundColor"].startswith("#"))
        self.assertTrue(all(item["selected"] for item in calendars))
        self.assertNotEqual(calendars[0]["id"], calendars[1]["id"])
        self.assertTrue(all(item["id"].startswith("yandex:account-1:") for item in calendars))
        self.assertEqual(request.call_count, 2)

    def test_account_id_separates_the_same_remote_calendar(self):
        def discover(account_id):
            with mock.patch.object(
                CALDAV, "request", side_effect=[HOME_RESPONSE, CALENDAR_RESPONSE]
            ):
                return CALDAV.discover(
                    "test@example.com", "application-password", account_id
                )[0]["id"]

        self.assertNotEqual(discover("first"), discover("second"))

    @unittest.skipUnless(HAS_ICALENDAR, "python-icalendar is not installed")
    def test_parses_calendar_query_events(self):
        calendar = {
            "id": "yandex:account-1:calendar-1",
            "remoteUrl": "https://caldav.yandex.ru/calendars/test/one/",
        }
        with mock.patch.object(CALDAV, "request", return_value=EVENT_RESPONSE):
            items = CALDAV.calendar_query(
                "test@example.com",
                "application-password",
                calendar,
                datetime.datetime(2026, 10, 6),
                datetime.datetime(2026, 10, 6),
            )

        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["summary"], "Yandex test event")
        self.assertEqual(items[0]["calendarId"], calendar["id"])
        self.assertEqual(
            items[0]["caldavHref"],
            "https://caldav.yandex.ru/calendars/test@example.com/one/event.ics",
        )


if __name__ == "__main__":
    unittest.main()
