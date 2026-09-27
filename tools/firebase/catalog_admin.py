"""Trusted catalog setup using the current Firebase CLI login.

Imports new bank records or reviews a submitted coordinator application.
Never include CLI credentials in the app.
"""
import argparse
import json
import math
from pathlib import Path
import re
import urllib.parse

from firestore_rest import call

PROJECT = 'bushel-volunteer-20260925'
ROOT = 'projects/' + PROJECT + '/databases/(default)/documents'
URL = 'https://firestore.googleapis.com/v1/' + ROOT


def safe_id(value):
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,128}', value):
        raise ValueError('Use a document ID with letters, numbers, underscores, or hyphens')
    return value


def bank_write(bank):
    required = {'id', 'name', 'shortName', 'description', 'address', 'hours', 'latitude', 'longitude'}
    if not required.issubset(bank) or set(bank) - (required | {'distance'}):
        raise ValueError('Bank fields must match the documented schema')
    bank_id = safe_id(bank['id'])
    fields = {}
    for field in required - {'id', 'latitude', 'longitude'} | ({'distance'} & set(bank)):
        value = bank[field]
        if not isinstance(value, str) or not value.strip() or len(value) > 4000:
            raise ValueError('Bank text fields must be nonempty strings of at most 4000 characters')
        fields[field] = {'stringValue': value.strip()}
    for field, limit in (('latitude', 90), ('longitude', 180)):
        value = bank[field]
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or abs(value) > limit:
            raise ValueError('Invalid bank coordinates')
        fields[field] = {'doubleValue': value}
    return {'update': {'name': ROOT + '/banks/' + bank_id, 'fields': fields},
            'currentDocument': {'exists': False}}


def access_write(uid, bank_id, grant):
    return {'update': {
        'name': ROOT + '/coordinatorApplications/' + safe_id(uid) + '/banks/' + safe_id(bank_id),
        'fields': {'status': {'stringValue': 'approved' if grant else 'rejected'}}},
        'updateMask': {'fieldPaths': ['status']}, 'currentDocument': {'exists': True}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    importer = commands.add_parser('import-banks')
    importer.add_argument('file', type=Path, help='JSON array of bank records')
    commands.add_parser('audit-groups', help='Read-only check for shifts missing their group record')
    for command in ('approve', 'reject', 'grant', 'revoke'):
        access = commands.add_parser(command)
        access.add_argument('--uid', required=True, type=safe_id)
        access.add_argument('--bank', required=True, type=safe_id)
    args = parser.parse_args()
    config = Path.home() / '.config/configstore/firebase-tools.json'
    token = json.loads(config.read_text(encoding='utf-8'))['tokens']['access_token']
    if args.command == 'audit-groups':
        page, total, missing = '', 0, []
        while True:
            result = call(URL + '/shifts?pageSize=100' + ('&pageToken=' + urllib.parse.quote(page) if page else ''), token=token)
            for shift in result.get('documents', []):
                total += 1
                sid = shift['name'].rsplit('/', 1)[1]
                try: call(URL + '/groups/' + sid, token=token)
                except RuntimeError as error:
                    if 'got 404:' not in str(error): raise
                    missing.append(sid)
            page = result.get('nextPageToken', '')
            if not page: break
        print('%s shifts; %s missing group records' % (total, len(missing)))
        for sid in missing: print('Missing group: ' + sid)
        if missing: raise SystemExit('Backfill these groups before deploying Slice 20 rules.')
    elif args.command == 'import-banks':
        banks = json.loads(args.file.read_text(encoding='utf-8'))
        if not isinstance(banks, list) or not 1 <= len(banks) <= 100:
            raise ValueError('Provide 1 to 100 bank records')
        writes = [bank_write(bank) for bank in banks]
        if len({write['update']['name'] for write in writes}) != len(writes):
            raise ValueError('Bank IDs must be unique')
        call(URL + ':commit', 'POST', {'writes': writes}, token)
        print('Created %s bank records in %s; existing records are never overwritten' % (len(writes), PROJECT))
    else:
        call(URL + '/banks/' + args.bank, token=token)
        application = call(URL + '/coordinatorApplications/' + args.uid + '/banks/' + args.bank, token=token)
        write = access_write(args.uid, args.bank, args.command in ('approve', 'grant'))
        write['currentDocument'] = {'updateTime': application['updateTime']}
        call(URL + ':commit', 'POST', {'writes': [write]}, token)
        print('%s applied for UID %s, bank %s in %s' % (args.command, args.uid, args.bank, PROJECT))


if __name__ == '__main__':
    main()
