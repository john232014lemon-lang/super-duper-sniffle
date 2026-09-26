"""Opt-in live Firebase Auth check; creates and deletes its own temporary users.

Run from the repository root after enabling Email/Password:
    python tools/firebase/auth_smoke_test.py

No admin credentials, passwords, or tokens are written to disk or printed.
This checks the backend with each configured API key, not platform UI behavior.
"""

import json
from pathlib import Path
import re
import secrets
import urllib.error
import urllib.parse
import urllib.request


class AuthRequestError(Exception):
    pass


def request(url, payload, form=False):
    body = urllib.parse.urlencode(payload) if form else json.dumps(payload)
    content_type = (
        "application/x-www-form-urlencoded" if form else "application/json"
    )
    req = urllib.request.Request(
        url, data=body.encode(), headers={"Content-Type": content_type}
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        result = json.loads(error.read())
        raise AuthRequestError(result.get("error", {}).get("message", "HTTP error")) from None


def check(platform, api_key):
    origin = "https://identitytoolkit.googleapis.com/v1/accounts:"
    suffix = "?key=" + urllib.parse.quote(api_key)
    email = "bushel-smoke-" + secrets.token_hex(10) + "@example.com"
    password = secrets.token_urlsafe(24)
    token = None
    try:
        created = request(origin + "signUp" + suffix, {
            "email": email, "password": password, "returnSecureToken": True,
        })
        token = created["idToken"]
        signed_in = request(origin + "signInWithPassword" + suffix, {
            "email": email, "password": password, "returnSecureToken": True,
        })
        if signed_in["localId"] != created["localId"]:
            raise RuntimeError("Sign-in returned a different account")
        token = signed_in["idToken"]
        refreshed = request("https://securetoken.googleapis.com/v1/token" + suffix, {
            "grant_type": "refresh_token", "refresh_token": signed_in["refreshToken"],
        }, form=True)
        if refreshed["user_id"] != created["localId"]:
            raise RuntimeError("Refresh returned a different account")
        token = refreshed["id_token"]
        try:
            request(origin + "signInWithPassword" + suffix, {
                "email": email, "password": "incorrect-" + password,
                "returnSecureToken": True,
            })
        except AuthRequestError as error:
            if str(error) not in ("INVALID_LOGIN_CREDENTIALS", "INVALID_PASSWORD"):
                raise
        else:
            raise RuntimeError("Incorrect password was accepted")
        print(platform + ": signup, sign-in, token refresh, and wrong-password rejection passed")
    finally:
        if token:
            request(origin + "delete" + suffix, {"idToken": token})
            print(platform + ": temporary account deleted")


if __name__ == "__main__":
    options = (Path(__file__).resolve().parents[2] / "lib/firebase_options.dart").read_text()
    for target in ("web", "android"):
        match = re.search(
            r"static const FirebaseOptions " + target + r" = FirebaseOptions\(\s*apiKey: '([^']+)'",
            options,
        )
        if not match:
            raise SystemExit("Missing generated Firebase options for " + target)
        try:
            check(target, match.group(1))
        except Exception as error:
            raise SystemExit(target + ": " + str(error)) from None
