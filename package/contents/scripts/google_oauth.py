#!/usr/bin/env python3

"""Complete Google OAuth for the plasmoid using a loopback callback and PKCE."""

import argparse
import base64
import hashlib
import http.server
import json
import secrets
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"
DEFAULT_SCOPES = (
    "https://www.googleapis.com/auth/calendar "
    "https://www.googleapis.com/auth/tasks"
)


def base64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def build_authorization_url(client_id, redirect_uri, state, code_challenge, scopes):
    params = {
        "access_type": "offline",
        "client_id": client_id,
        "code_challenge": code_challenge,
        "code_challenge_method": "S256",
        "include_granted_scopes": "true",
        "prompt": "consent",
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scopes,
        "state": state,
    }
    return AUTHORIZATION_ENDPOINT + "?" + urllib.parse.urlencode(params)


class CallbackServer(http.server.HTTPServer):
    allow_reuse_address = True


class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        if "code" not in query and "error" not in query:
            self.send_error(404)
            return

        self.server.oauth_result = {
            "code": query.get("code", [""])[0],
            "error": query.get("error", [""])[0],
            "state": query.get("state", [""])[0],
        }
        success = bool(self.server.oauth_result["code"])
        title = "Login complete" if success else "Login failed"
        message = (
            "You can close this window and return to the Event Calendar settings."
            if success
            else "Return to the Event Calendar settings and try again."
        )
        body = (
            "<!doctype html><html><head><meta charset='utf-8'>"
            f"<title>{title}</title></head><body><h2>{title}</h2>"
            f"<p>{message}</p></body></html>"
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format, *_args):
        return


def open_browser(url):
    for command in (("xdg-open", url), ("gio", "open", url)):
        try:
            subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return True
        except FileNotFoundError:
            continue
        except OSError:
            continue
    return False


def wait_for_callback(server, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline and not hasattr(server, "oauth_result"):
        server.timeout = min(1.0, max(0.0, deadline - time.monotonic()))
        server.handle_request()
    return getattr(server, "oauth_result", None)


def exchange_code(client_id, client_secret, code, redirect_uri, code_verifier):
    params = {
        "client_id": client_id,
        "code": code,
        "code_verifier": code_verifier,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri,
    }
    if client_secret:
        params["client_secret"] = client_secret

    request = urllib.request.Request(
        TOKEN_ENDPOINT,
        data=urllib.parse.urlencode(params).encode("ascii"),
        headers={
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        try:
            data = json.loads(error.read().decode("utf-8"))
            detail = data.get("error_description") or data.get("error")
        except (UnicodeDecodeError, json.JSONDecodeError):
            detail = None
        raise RuntimeError(detail or f"token endpoint returned HTTP {error.code}") from error
    except (urllib.error.URLError, socket.timeout) as error:
        raise RuntimeError("could not connect to the token endpoint") from error


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client-id", required=True)
    parser.add_argument("--client-secret", default="")
    parser.add_argument("--scopes", default=DEFAULT_SCOPES)
    parser.add_argument("--timeout", type=int, default=300)
    return parser.parse_args()


def main():
    args = parse_args()
    if args.timeout <= 0:
        print("invalid callback timeout", file=sys.stderr)
        return 2

    state = secrets.token_urlsafe(32)
    code_verifier = secrets.token_urlsafe(64)
    code_challenge = base64url(hashlib.sha256(code_verifier.encode("ascii")).digest())

    try:
        server = CallbackServer(("127.0.0.1", 0), CallbackHandler)
    except OSError as error:
        print(f"could not start the local callback server: {error}", file=sys.stderr)
        return 3

    with server:
        redirect_uri = f"http://127.0.0.1:{server.server_port}/"
        authorization_url = build_authorization_url(
            args.client_id, redirect_uri, state, code_challenge, args.scopes
        )
        if not open_browser(authorization_url):
            print("could not open the default browser", file=sys.stderr)
            return 4

        result = wait_for_callback(server, args.timeout)

    if result is None:
        print("authorization timed out", file=sys.stderr)
        return 5
    if result["state"] != state:
        print("authorization state mismatch", file=sys.stderr)
        return 6
    if result["error"] or not result["code"]:
        print(result["error"] or "authorization was denied", file=sys.stderr)
        return 6

    try:
        token_data = exchange_code(
            args.client_id,
            args.client_secret,
            result["code"],
            redirect_uri,
            code_verifier,
        )
    except (RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"token exchange failed: {error}", file=sys.stderr)
        return 7

    if not token_data.get("access_token"):
        print("token response did not contain an access token", file=sys.stderr)
        return 7

    print(json.dumps(token_data, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
