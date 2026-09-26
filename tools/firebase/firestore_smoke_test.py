"""Test Firestore ownership rules with real Auth tokens (no admin bypass).

Run with --emulator under `firebase emulators:exec --project demo-bushel`,
or explicitly use --live after Email/Password is enabled. Both modes create
temporary users/documents and remove them. No credentials are printed/saved.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import urllib.error
import urllib.parse
import urllib.request


def call(url, method="GET", data=None, token=None, expected=200):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(
        url, method=method, headers=headers,
        data=json.dumps(data).encode() if data is not None else None,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            status = response.status
            result = json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        status = error.code
        result = json.loads(error.read() or b"{}")
    if status != expected:
        message = result.get("error", {}).get("message", "Unexpected response")
        raise RuntimeError("Expected HTTP %s, got %s: %s" % (expected, status, message))
    return result


def run(emulator):
    project = "demo-bushel" if emulator else "bushel-volunteer-20260925"
    if emulator:
        firestore_host = os.environ.get("FIRESTORE_EMULATOR_HOST", "")
        auth_host = os.environ.get("FIREBASE_AUTH_EMULATOR_HOST", "")
        # Never fall back to live services when a local emulator is missing.
        if firestore_host != "127.0.0.1:8080" or auth_host != "127.0.0.1:9099":
            raise RuntimeError("Start both emulators using firebase.json before this test")
        auth_origin = "http://" + auth_host + "/identitytoolkit.googleapis.com/v1"
        db_origin = "http://" + firestore_host
        api_key = "demo-key"
    else:
        options = (Path(__file__).resolve().parents[2] / "lib/firebase_options.dart").read_text()
        match = re.search(r"static const FirebaseOptions web = FirebaseOptions\(\s*apiKey: '([^']+)'", options)
        if not match:
            raise RuntimeError("Missing generated Web Firebase options")
        api_key = match.group(1)
        auth_origin = "https://identitytoolkit.googleapis.com/v1"
        db_origin = "https://firestore.googleapis.com"
    auth_suffix = "?key=" + urllib.parse.quote(api_key)
    document_root = "projects/" + project + "/databases/(default)/documents"
    documents_url = db_origin + "/v1/" + document_root
    accounts = []
    created = []
    checks = 0

    def write(path, token, expected=200, extra=False, timestamp=True, message="Bushel connection test"):
        fields = {"message": {"stringValue": message}}
        if extra:
            fields["unexpected"] = {"booleanValue": True}
        operation = {"update": {"name": document_root + "/" + path, "fields": fields},
                     "currentDocument": {"exists": False}}
        if timestamp:
            operation["updateTransforms"] = [{"fieldPath": "createdAt", "setToServerValue": "REQUEST_TIME"}]
        return call(documents_url + ":commit", "POST", {"writes": [operation]}, token, expected)

    try:
        for _ in range(2):
            account = call(auth_origin + "/accounts:signUp" + auth_suffix, "POST", {
                "email": "bushel-firestore-" + secrets.token_hex(10) + "@example.com",
                "password": secrets.token_urlsafe(24), "returnSecureToken": True,
            })
            accounts.append(account)
        owner, other = accounts
        token = owner["idToken"]
        path = "smokeTests/" + owner["localId"] + "/runs/" + secrets.token_hex(12)
        url = documents_url + "/" + path
        write(path, token)
        created.append((url, token))
        data = call(url, token=token)
        assert data["fields"]["message"]["stringValue"] == "Bushel connection test"
        assert "timestampValue" in data["fields"]["createdAt"]
        checks += 2

        for denied_token in (None, other["idToken"]):
            call(url, token=denied_token, expected=403)
            call(url, "DELETE", token=denied_token, expected=403)
            call(url, "PATCH", {"fields": {"message": {"stringValue": "tampered"}}}, denied_token, 403)
            write(path + "-denied", denied_token, expected=403)
            checks += 4

        # The owner can read/delete, but cannot list, update, or create invalid data.
        call(documents_url + "/smokeTests/" + owner["localId"] + "/runs", token=token, expected=403)
        call(url, "PATCH", {"fields": {"message": {"stringValue": "tampered"}}}, token, 403)
        write(path + "-extra", token, expected=403, extra=True)
        write(path + "-timestamp", token, expected=403, timestamp=False)
        write(path + "-message", token, expected=403, message="tampered")
        write("users/" + owner["localId"], token, expected=403)
        checks += 6

        other_path = "smokeTests/" + other["localId"] + "/runs/" + secrets.token_hex(12)
        write(other_path, other["idToken"])
        created.append((documents_url + "/" + other_path, other["idToken"]))
        call(documents_url + "/" + other_path, token=token, expected=403)
        checks += 2

        call(url, "DELETE", token=token)
        created.remove((url, token))
        call(url, token=token, expected=404)
        checks += 2

        # Slice 17: private adult profiles, persisted UI preference only.
        profile_path = "profiles/" + owner["localId"]
        profile_url = documents_url + "/" + profile_path
        fields = {"name": {"stringValue": "Test adult"},
                  "preferredRole": {"stringValue": "volunteer"},
                  "familyAccount": {"booleanValue": True}}

        def save_profile(data, credential=token, expected=200, path=profile_path, timestamp=True):
            operation = {"update": {"name": document_root + "/" + path, "fields": data}}
            if timestamp:
                operation["updateTransforms"] = [{"fieldPath": "updatedAt", "setToServerValue": "REQUEST_TIME"}]
            return call(documents_url + ":commit", "POST", {"writes": [operation]}, credential, expected)

        save_profile(fields)
        created.append((profile_url, token))
        assert call(profile_url, token=token)["fields"]["name"] == fields["name"]
        checks += 2
        for credential in (None, other["idToken"]):
            call(profile_url, token=credential, expected=403)
            call(profile_url, "DELETE", token=credential, expected=403)
            save_profile(fields, credential, 403)
            checks += 3
        save_profile(fields, path="profiles/" + other["localId"], expected=403)
        call(documents_url + "/profiles", token=token, expected=403)
        save_profile(fields, timestamp=False, expected=403)
        checks += 3
        for invalid in (
                {**fields, "role": {"stringValue": "admin"}},
                {**fields, "isAdmin": {"booleanValue": True}},
                {**fields, "preferredRole": {"stringValue": "kid"}},
                {**fields, "name": {"stringValue": ""}},
                {**fields, "name": {"stringValue": " "}},
                {**fields, "name": {"stringValue": "x" * 81}},
                {**fields, "familyAccount": {"stringValue": "true"}},
                {key: value for key, value in fields.items() if key != "name"}):
            save_profile(invalid, expected=403)
            checks += 1
        fields["preferredRole"] = {"stringValue": "coordinator"}
        save_profile(fields)
        # A fresh token/session still sees the saved profile.
        refreshed = call(auth_origin.replace("identitytoolkit", "securetoken") + "/token" + auth_suffix,
                         "POST", {"grant_type": "refresh_token", "refresh_token": owner["refreshToken"]})
        saved = call(profile_url, token=refreshed["id_token"])
        assert saved["fields"]["preferredRole"]["stringValue"] == "coordinator"
        assert "timestampValue" in saved["fields"]["updatedAt"]
        write("shifts/forged-permission-test", token, expected=403)
        write("banks/forged-permission-test", token, expected=403)
        checks += 4
        call(profile_url, "DELETE", token=token)
        created.remove((profile_url, token))
        call(profile_url, token=token, expected=404)
        checks += 2
        print("%s: %s Firestore ownership/schema checks passed" % ("Emulator" if emulator else "Live", checks))
    finally:
        errors = []
        for url, token in created:
            try:
                call(url, "DELETE", token=token)
            except Exception as error:
                errors.append(str(error))
        for account in accounts:
            try:
                call(auth_origin + "/accounts:delete" + auth_suffix, "POST", {"idToken": account["idToken"]})
            except Exception as error:
                errors.append(str(error))
        if errors:
            raise RuntimeError("Temporary test cleanup failed: " + "; ".join(errors))
        if accounts:
            print("Temporary accounts and documents cleaned up")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--emulator", action="store_true")
    mode.add_argument("--live", action="store_true")
    arguments = parser.parse_args()
    try:
        run(arguments.emulator)
    except Exception as error:
        raise SystemExit(str(error)) from None
