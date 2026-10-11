#!/usr/bin/env python3
"""Read-only connectivity checks for the configured FixPK Supabase project."""

import argparse
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def check(label: str, url: str, headers: dict[str, str]) -> bool:
    try:
        with urlopen(Request(url, headers=headers, method="GET"), timeout=15) as response:
            status = response.status
    except HTTPError as error:
        status = error.code
    except (URLError, TimeoutError, OSError):
        print(f"FAIL {label}: request failed")
        return False

    passed = 200 <= status < 300
    print(f"{'PASS' if passed else 'FAIL'} {label}: HTTP {status}")
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        default="config/development.json",
        help="ignored Flutter dart-define JSON file (default: config/development.json)",
    )
    args = parser.parse_args()

    try:
        config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        print("FAIL configuration: file could not be read")
        return 2

    base_url = str(config.get("SUPABASE_URL", "")).rstrip("/")
    key = str(config.get("SUPABASE_PUBLISHABLE_KEY", ""))
    if (
        config.get("FOUNDATION_PREVIEW") != "false"
        or not base_url.startswith("https://")
        or not key.startswith("sb_publishable_")
    ):
        print("FAIL configuration: connected mode needs an HTTPS URL and publishable key")
        return 2

    common_headers = {"apikey": key, "Authorization": f"Bearer {key}"}
    checks = [
        ("Auth settings", f"{base_url}/auth/v1/settings", {"apikey": key}),
        (
            "Public service categories",
            f"{base_url}/rest/v1/service_categories?select=id&limit=1",
            common_headers,
        ),
        (
            "Public services",
            f"{base_url}/rest/v1/services?select=id&limit=1",
            common_headers,
        ),
        (
            "Published FAQ",
            f"{base_url}/rest/v1/faq?select=id&is_published=eq.true&limit=1",
            common_headers,
        ),
    ]
    return 0 if all(check(*item) for item in checks) else 1


if __name__ == "__main__":
    sys.exit(main())
