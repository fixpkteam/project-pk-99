#!/usr/bin/env python3
"""Read-only API probes; never print keys, tokens or returned customer data."""

import argparse
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from time import perf_counter
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


PUBLIC_TABLES = (
    'service_categories', 'services', 'service_questions',
    'service_question_options', 'service_areas', 'product_categories',
    'products', 'product_images', 'product_specifications', 'projects',
    'project_images', 'faq', 'banners', 'app_content',
)
PRIVATE_TABLES = (
    'profiles', 'addresses', 'service_requests', 'service_request_answers',
    'request_attachments', 'site_surveys', 'appointments', 'quotes',
    'quote_items', 'jobs', 'job_assignments', 'notifications', 'support_tickets',
)


def check(item: tuple) -> bool:
    label, url, headers, expectation, body = item
    start = perf_counter()
    try:
        request = Request(url, headers=headers, data=body,
                          method='POST' if body is not None else 'GET')
        try:
            with urlopen(request, timeout=20) as response:
                status, payload = response.status, response.read(65536)
        except HTTPError as error:
            status, payload = error.code, error.read(65536)
    except (URLError, TimeoutError, OSError) as error:
        print(f'FAIL {label}: connection failed ({type(error).__name__})')
        return False

    if expectation == 'denied':
        passed = status in (401, 403)
    elif expectation == 'private':
        # RLS-filtered SELECT returns [] or the table rejects anonymous access.
        passed = status in (401, 403) or (status == 200 and payload.strip() == b'[]')
    else:
        passed = 200 <= status < 300
        if passed:
            try:
                json.loads(payload)
            except (ValueError, UnicodeDecodeError):
                passed = False
    elapsed = round((perf_counter() - start) * 1000)
    print(f"{'PASS' if passed else 'FAIL'} {label}: HTTP {status}, {elapsed} ms")
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='config/development.json')
    args = parser.parse_args()
    try:
        config = json.loads(Path(args.config).read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError):
        print('FAIL configuration: file could not be read')
        return 2
    base = str(config.get('SUPABASE_URL', '')).rstrip('/')
    key = str(config.get('SUPABASE_PUBLISHABLE_KEY', ''))
    if (config.get('FOUNDATION_PREVIEW') != 'false'
            or not base.startswith('https://') or not key.startswith('sb_publishable_')):
        print('FAIL configuration: connected mode needs an HTTPS URL and publishable key')
        return 2
    headers = {'apikey': key, 'Content-Type': 'application/json'}
    checks = [('Auth settings', f'{base}/auth/v1/settings', headers, 'public', None)]
    checks += [(f'Public {table}', f'{base}/rest/v1/{table}?select=id&limit=1',
                headers, 'public', None) for table in PUBLIC_TABLES]
    checks += [(f'Anonymous cannot read {table}',
                f'{base}/rest/v1/{table}?select=*&limit=1',
                headers, 'private', None) for table in PRIVATE_TABLES]
    checks += [
        ('Anonymous request RPC denied', f'{base}/rest/v1/rpc/submit_service_request',
         headers, 'denied', json.dumps({
             'p_request_id': '00000000-0000-4000-8000-000000000001',
             'p_service_id': '00000000-0000-4000-8000-000000000002',
             'p_address_id': '00000000-0000-4000-8000-000000000003',
             'p_customer_notes': '', 'p_preferred_date': None,
             'p_preferred_time': None, 'p_answers': {},
         }).encode()),
        ('Anonymous admin function denied', f'{base}/functions/v1/admin-user-management',
         headers, 'denied', b'{"action":"list"}'),
    ]
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(check, checks))
    print(f'{sum(results)}/{len(results)} checks passed. These are API timings, not device performance measurements.')
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
