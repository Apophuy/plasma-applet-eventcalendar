#!/usr/bin/env python3

"""Small CalDAV bridge for Yandex Calendar.

The widget deliberately keeps CalDAV passwords out of KConfig. This helper
prompts for an application password and stores it in a user-only local file,
then performs CalDAV discovery and range queries without ever returning the
password to QML or passing it as a command-line argument.
"""

import argparse
import base64
import datetime
import hashlib
import json
import os
import pathlib
import stat
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

CALDAV_ORIGIN = "https://caldav.yandex.ru"
DAV = "DAV:"
CALDAV = "urn:ietf:params:xml:ns:caldav"
APPLE_ICAL = "http://apple.com/ns/ical/"
REQUEST_TIMEOUT_SECONDS = 30
MAX_RESPONSE_BYTES = 20 * 1024 * 1024
MAX_PASSWORD_BYTES = 16 * 1024
CREDENTIAL_DIRECTORY_NAME = "apophuy-calendar/yandex-credentials"
DEFAULT_COLORS = (
    "#ffcc00",
    "#ff8a65",
    "#66bb6a",
    "#42a5f5",
    "#7e57c2",
    "#ec407a",
    "#26a69a",
    "#78909c",
)


class CalDavError(RuntimeError):
    pass


class CredentialMissingError(CalDavError):
    pass


def validate_caldav_url(url):
    parsed = urllib.parse.urlparse(url)
    try:
        port = parsed.port
    except ValueError as error:
        raise CalDavError("Yandex returned an invalid CalDAV URL.") from error
    if (
        parsed.scheme != "https"
        or parsed.hostname != "caldav.yandex.ru"
        or parsed.username is not None
        or parsed.password is not None
        or port not in (None, 443)
    ):
        raise CalDavError("Yandex returned an unsafe CalDAV URL.")
    return url


class CalDavRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        validate_caldav_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


CALDAV_OPENER = urllib.request.build_opener(CalDavRedirectHandler())


def credential_directory():
    data_home = os.environ.get("XDG_DATA_HOME")
    base = pathlib.Path(data_home) if data_home else pathlib.Path.home() / ".local/share"
    directory = base / CREDENTIAL_DIRECTORY_NAME
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    if directory.is_symlink() or not directory.is_dir():
        raise CalDavError("The local Yandex credential directory is unsafe.")
    os.chmod(directory, 0o700)
    return directory


def credential_path(account_id):
    digest = hashlib.sha256(account_id.encode("utf-8")).hexdigest()
    return credential_directory() / (digest + ".password")


def run_command(args, **kwargs):
    try:
        return subprocess.run(args, check=False, **kwargs)
    except OSError as error:
        raise CalDavError(str(error)) from error


def read_password(account_id):
    path = credential_path(account_id)
    flags = os.O_RDONLY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        file_descriptor = os.open(path, flags)
    except FileNotFoundError as error:
        raise CredentialMissingError(
            "The Yandex application password is not configured."
        ) from error
    except OSError as error:
        raise CalDavError(
            "Could not read the local Yandex application password."
        ) from error
    try:
        file_status = os.fstat(file_descriptor)
        if not stat.S_ISREG(file_status.st_mode) or file_status.st_uid != os.getuid():
            raise CalDavError("The local Yandex credential file is unsafe.")
        data = os.read(file_descriptor, MAX_PASSWORD_BYTES + 1)
    finally:
        os.close(file_descriptor)
    if len(data) > MAX_PASSWORD_BYTES:
        raise CalDavError("The saved Yandex application password is too large.")
    try:
        password = data.decode("utf-8")
    except UnicodeDecodeError as error:
        raise CalDavError(
            "The saved Yandex application password is invalid."
        ) from error
    if not password:
        raise CredentialMissingError(
            "The Yandex application password is not configured."
        )
    return password


def write_password(account_id, password):
    data = password.encode("utf-8")
    if not data or len(data) > MAX_PASSWORD_BYTES:
        raise CalDavError("The Yandex application password is invalid.")
    directory = credential_directory()
    destination = credential_path(account_id)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=".credential-", dir=directory
    )
    try:
        os.fchmod(file_descriptor, 0o600)
        with os.fdopen(file_descriptor, "wb") as credential_file:
            file_descriptor = -1
            credential_file.write(data)
            credential_file.flush()
            os.fsync(credential_file.fileno())
        os.replace(temporary_name, destination)
        os.chmod(destination, 0o600)
    except OSError as error:
        raise CalDavError(
            "Could not save the local Yandex application password."
        ) from error
    finally:
        if file_descriptor >= 0:
            os.close(file_descriptor)
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass


def forget_password(account_id):
    try:
        credential_path(account_id).unlink()
    except FileNotFoundError:
        pass
    except OSError as error:
        raise CalDavError(
            "Could not remove the local Yandex application password."
        ) from error


def prompt_password(title, prompt):
    result = run_command(
        [
            "kdialog",
            "--title",
            title,
            "--password",
            prompt,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise CalDavError("Yandex Calendar connection was cancelled.")
    password = result.stdout.rstrip("\r\n")
    if not password:
        raise CalDavError("The Yandex application password cannot be empty.")
    return password


def authorization_header(login, password):
    value = (login + ":" + password).encode("utf-8")
    return "Basic " + base64.b64encode(value).decode("ascii")


def request(login, password, method, url, body=None, depth=None):
    validate_caldav_url(url)
    headers = {
        "Accept": "application/xml, text/calendar;q=0.9, */*;q=0.1",
        "Authorization": authorization_header(login, password),
        "User-Agent": "KDE Apophuy Calendar CalDAV client",
    }
    if body is not None:
        headers["Content-Type"] = "application/xml; charset=utf-8"
    if depth is not None:
        headers["Depth"] = str(depth)
    req = urllib.request.Request(
        url,
        data=body.encode("utf-8") if isinstance(body, str) else body,
        headers=headers,
        method=method,
    )
    try:
        with CALDAV_OPENER.open(req, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            data = response.read(MAX_RESPONSE_BYTES + 1)
    except urllib.error.HTTPError as error:
        if error.code == 401:
            raise CalDavError(
                "Yandex rejected the login or application password."
            ) from error
        raise CalDavError("Yandex CalDAV returned HTTP {}.".format(error.code)) from error
    except urllib.error.URLError as error:
        raise CalDavError("Could not connect to Yandex Calendar.") from error
    if len(data) > MAX_RESPONSE_BYTES:
        raise CalDavError("The Yandex CalDAV response is too large.")
    return data


def first_text(element, namespace, name):
    child = element.find(".//{{{}}}{}".format(namespace, name))
    return (child.text or "").strip() if child is not None else ""


def absolute_url(base, href):
    return validate_caldav_url(urllib.parse.urljoin(base, href))


def principal_url(login):
    encoded_login = urllib.parse.quote(login, safe="@")
    return "{}/principals/users/{}/".format(CALDAV_ORIGIN, encoded_login)


def discover(login, password, account_id):
    principal = principal_url(login)
    home_body = """<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop><c:calendar-home-set /></d:prop>
</d:propfind>"""
    home_data = request(login, password, "PROPFIND", principal, home_body, 0)
    try:
        home_root = ET.fromstring(home_data)
    except ET.ParseError as error:
        raise CalDavError("Yandex returned invalid CalDAV discovery data.") from error
    home_href_element = home_root.find(
        ".//{{{}}}calendar-home-set/{{{}}}href".format(CALDAV, DAV)
    )
    home_href = (
        (home_href_element.text or "").strip()
        if home_href_element is not None
        else ""
    )
    if not home_href:
        raise CalDavError("Yandex did not return a CalDAV calendar home.")
    home_url = absolute_url(principal, home_href)

    calendars_body = """<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:a="http://apple.com/ns/ical/">
  <d:prop>
    <d:displayname />
    <d:resourcetype />
    <d:current-user-privilege-set />
    <a:calendar-color />
  </d:prop>
</d:propfind>"""
    data = request(login, password, "PROPFIND", home_url, calendars_body, 1)
    try:
        root = ET.fromstring(data)
    except ET.ParseError as error:
        raise CalDavError("Yandex returned an invalid calendar list.") from error

    calendars = []
    for response in root.findall(".//{{{}}}response".format(DAV)):
        resource_type = response.find(
            ".//{{{}}}resourcetype/{{{}}}calendar".format(DAV, CALDAV)
        )
        if resource_type is None:
            continue
        href = first_text(response, DAV, "href")
        if not href:
            continue
        remote_url = absolute_url(home_url, href)
        digest = hashlib.sha256(remote_url.encode("utf-8")).hexdigest()[:20]
        calendar_id = "yandex:{}:{}".format(account_id, digest)
        name = first_text(response, DAV, "displayname") or "Yandex Calendar"
        color = first_text(response, APPLE_ICAL, "calendar-color")
        color = color[:7] if color.startswith("#") else ""
        if not color:
            color = DEFAULT_COLORS[len(calendars) % len(DEFAULT_COLORS)]
        calendars.append(
            {
                "id": calendar_id,
                "remoteUrl": remote_url,
                "summary": name,
                "backgroundColor": color,
                "foregroundColor": "",
                "selected": True,
                "accessRole": "reader",
            }
        )
    if not calendars:
        raise CalDavError("No calendars were found in this Yandex account.")
    return calendars


def parse_date(value):
    return datetime.datetime.strptime(value, "%Y-%m-%d")


def calendar_query(login, password, calendar, start, end):
    import icsjson

    # CalDAV time-range timestamps are UTC. A one-day margin prevents local
    # dates near UTC boundaries from being omitted; icsjson filters precisely.
    start_utc = (start - datetime.timedelta(days=1)).strftime("%Y%m%dT000000Z")
    end_exclusive = end + datetime.timedelta(days=2)
    end_utc = end_exclusive.strftime("%Y%m%dT000000Z")
    body = """<?xml version="1.0" encoding="utf-8" ?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop><d:getetag /><c:calendar-data /></d:prop>
  <c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">
    <c:time-range start="{start}" end="{end}" />
  </c:comp-filter></c:comp-filter></c:filter>
</c:calendar-query>""".format(start=start_utc, end=end_utc)
    data = request(
        login,
        password,
        "REPORT",
        calendar["remoteUrl"],
        body,
        1,
    )
    try:
        root = ET.fromstring(data)
    except ET.ParseError as error:
        raise CalDavError("Yandex returned invalid event data.") from error

    items = []
    for response in root.findall(".//{{{}}}response".format(DAV)):
        href = first_text(response, DAV, "href")
        etag = first_text(response, DAV, "getetag")
        calendar_data = first_text(response, CALDAV, "calendar-data")
        if not calendar_data:
            continue
        parser = icsjson.CalendarManager(calendar["remoteUrl"])
        parser.read_data(calendar_data.encode("utf-8"))
        for occurrence in parser.query(start, end):
            item = json.loads(icsjson.events_to_json([occurrence]))["items"][0]
            item["calendarId"] = calendar["id"]
            item["caldavHref"] = absolute_url(calendar["remoteUrl"], href)
            item["etag"] = etag
            item["htmlLink"] = "https://calendar.yandex.ru/"
            items.append(item)
    return items


def decode_calendars(value):
    try:
        return json.loads(base64.b64decode(value).decode("utf-8"))
    except (ValueError, UnicodeDecodeError) as error:
        raise CalDavError("The saved Yandex calendar list is invalid.") from error


def command_connect(args):
    password = prompt_password(args.title, args.prompt)
    calendars = discover(args.login, password, args.account_id)
    write_password(args.account_id, password)
    return {"calendars": calendars}


def command_discover(args):
    password = read_password(args.account_id)
    return {"calendars": discover(args.login, password, args.account_id)}


def command_query(args):
    password = read_password(args.account_id)
    start = parse_date(args.start)
    end = parse_date(args.end)
    items = []
    for calendar in decode_calendars(args.calendars):
        if calendar.get("selected", True):
            items.extend(calendar_query(args.login, password, calendar, start, end))
    return {"items": items}


def command_forget(args):
    forget_password(args.account_id)
    return {"forgotten": True}


def main():
    parser = argparse.ArgumentParser(description="Yandex Calendar CalDAV bridge")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("connect", "discover"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--account-id", required=True)
        subparser.add_argument("--login", required=True)
        if command == "connect":
            subparser.add_argument("--title", default="Apophuy Calendar")
            subparser.add_argument(
                "--prompt",
                default="Enter the Yandex Calendar application password:",
            )
    query_parser = subparsers.add_parser("query")
    query_parser.add_argument("--account-id", required=True)
    query_parser.add_argument("--login", required=True)
    query_parser.add_argument("--calendars", required=True)
    query_parser.add_argument("--start", required=True)
    query_parser.add_argument("--end", required=True)
    forget_parser = subparsers.add_parser("forget")
    forget_parser.add_argument("--account-id", required=True)
    args = parser.parse_args()

    commands = {
        "connect": command_connect,
        "discover": command_discover,
        "query": command_query,
        "forget": command_forget,
    }
    try:
        result = commands[args.command](args)
    except CredentialMissingError as error:
        print(str(error), file=sys.stderr)
        return 5
    except CalDavError as error:
        print(str(error), file=sys.stderr)
        return 2
    except Exception as error:
        print("Yandex Calendar error: {}".format(error), file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
