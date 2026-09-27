"""Small HTTP helper for the trusted catalog administration commands."""
import json
import urllib.error
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
