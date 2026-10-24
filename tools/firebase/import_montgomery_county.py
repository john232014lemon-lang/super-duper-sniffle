"""One-time, create-only import requested by the project owner on October 23.

Default: validate local data and print the proposed catalog entries.
--apply: verify public event availability and John C, then atomically create
the bank, approved coordinator assignment, shifts and their empty groups.
Uses the existing Firebase CLI login; never prints credentials or deploys rules.
"""
import argparse
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import urllib.request

from catalog_admin import ROOT, URL, bank_write, safe_id
from firestore_rest import call


def load_manifest():
    data = json.loads(Path(__file__).with_name('montgomery_county_202610.json').read_text(encoding='utf-8'))
    bank_write(data['bank'])
    safe_id(data['coordinatorUid'])
    assert len(data['shifts']) == 2
    assert len({s['id'] for s in data['shifts']}) == 2
    for shift in data['shifts']:
        safe_id(shift['id'])
        assert 0 < len(shift['title']) <= 40
        assert 0 < len(shift['station']) <= 30
        assert len(shift['instructions']) <= 500
        assert 1 <= shift['capacity'] <= 500
        start = datetime.fromisoformat(shift['date'] + 'T' + shift['time'])
        end = datetime.fromisoformat(shift['date'] + 'T' + shift['endTime'])
        assert end > start
        assert shift['utcOffsetMinutes'] == -300  # Central daylight time on these dates.
    return data


def create_write(path, fields, timestamps=()):
    write = {
        'update': {'name': ROOT + '/' + path, 'fields': fields},
        'currentDocument': {'exists': False},
    }
    if timestamps:
        write['updateTransforms'] = [
            {'fieldPath': field, 'setToServerValue': 'REQUEST_TIME'}
            for field in timestamps
        ]
    return write


def timestamp(value):
    return {'timestampValue': value.astimezone(timezone.utc).isoformat().replace('+00:00', 'Z')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    data = load_manifest()
    print('Project: bushel-volunteer-20260925 / (default)')
    print('Bank: ' + data['bank']['name'] + '; coordinator: ' + data['coordinatorName'])
    for shift in data['shifts']:
        print('%s: %s %s-%s Central; %s open slots' % (
            shift['title'], shift['date'], shift['time'], shift['endTime'], shift['capacity']))
    if not args.apply:
        print('Local validation only. No database reads or writes.')
        return

    token = json.loads((Path.home() / '.config/configstore/firebase-tools.json').read_text(encoding='utf-8'))['tokens']['access_token']
    profile = call(URL + '/profiles/' + data['coordinatorUid'], token=token)
    assert profile['fields']['name']['stringValue'] == data['coordinatorName'], 'Coordinator identity changed'
    assert profile['fields']['preferredRole']['stringValue'] == 'coordinator'

    for shift in data['shifts']:
        request = urllib.request.Request(
            'https://mcfoodbank.volunteerhub.com/internalapi/volunteerview/view/event/' + shift['eventId'],
            headers={'X-Requested-With': 'XMLHttpRequest'},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            event = json.load(response)['evt']
        assert event['name'] == shift['title'], 'Source title changed'
        assert event['sTime'] == shift['date'] + 'T' + shift['time'] + ':00', 'Source start changed'
        assert event['eTime'] == shift['date'] + 'T' + shift['endTime'] + ':00', 'Source end changed'
        assert event['disposition']['slotsRemaining'] == shift['capacity'], 'Displayed open slots changed; review before import'
        assert event['disposition']['showSignup'], 'Source no longer accepts registration'

    writes = [bank_write(data['bank'])]
    bank_id = data['bank']['id']
    writes.append(create_write('coordinatorApplications/' + data['coordinatorUid'] + '/banks/' + bank_id, {
        'name': {'stringValue': data['coordinatorName']},
        'contact': {'stringValue': 'Assigned directly by the project administrator'},
        'reason': {'stringValue': 'Project owner requested John C as coordinator for these imported Montgomery County Food Bank shifts.'},
        'status': {'stringValue': 'approved'},
    }, ('submittedAt',)))
    for shift in data['shifts']:
        zone = timezone(timedelta(minutes=shift['utcOffsetMinutes']))
        start = datetime.fromisoformat(shift['date'] + 'T' + shift['time']).replace(tzinfo=zone)
        assert start > datetime.now(timezone.utc), 'Shift has already started'
        fields = {
            k: {'stringValue': v} for k, v in {
                'bankId': bank_id, 'creatorUid': data['coordinatorUid'],
                'title': shift['title'], 'time': shift['time'],
                'station': shift['station'], 'instructions': shift['instructions'],
            }.items()
        }
        fields.update({
            'date': timestamp(datetime.fromisoformat(shift['date']).replace(tzinfo=timezone.utc)),
            'startsAt': timestamp(start),
            'utcOffsetMinutes': {'integerValue': str(shift['utcOffsetMinutes'])},
            'capacity': {'integerValue': str(shift['capacity'])},
            'signupCount': {'integerValue': '0'},
        })
        writes.append(create_write('shifts/' + shift['id'], fields, ('createdAt',)))
        writes.append(create_write('groups/' + shift['id'], {
            'members': {'mapValue': {'fields': {}}},
            'seats': {'mapValue': {'fields': {}}},
            'version': {'integerValue': '0'},
            'banned': {'arrayValue': {'values': []}},
        }))
    call(URL + ':commit', 'POST', {'writes': writes}, token)
    print('Created bank, coordinator approval, two shifts and two groups atomically.')
    for write in writes:
        saved = call('https://firestore.googleapis.com/v1/' + write['update']['name'], token=token)
        for key, value in write['update']['fields'].items():
            actual = saved['fields'][key]
            # Firestore omits empty fields/values in map and array responses.
            if value in ({'mapValue': {'fields': {}}}, {'arrayValue': {'values': []}}):
                assert actual.get('mapValue', actual.get('arrayValue')) in ({}, {'fields': {}}, {'values': []})
            elif 'timestampValue' in value:
                assert datetime.fromisoformat(actual['timestampValue'].replace('Z', '+00:00')) == datetime.fromisoformat(value['timestampValue'].replace('Z', '+00:00'))
            else:
                assert actual == value, 'Read-back mismatch: ' + key
        print('Verified: ' + saved['name'].split('/documents/')[1])


if __name__ == '__main__':
    main()
