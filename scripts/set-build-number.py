#!/usr/bin/env python3
"""Use the project-wide Codemagic sequence, never a hard-coded repeated build."""
import os
import plistlib
from pathlib import Path

def compute(sequence, offset):
    if not sequence.isdecimal() or not offset.isdecimal():
        raise ValueError('PROJECT_BUILD_NUMBER and BUILD_NUMBER_OFFSET must be integers.')
    number = int(sequence) + int(offset)
    if not 1 <= number <= 9999:
        raise ValueError('Build number must be 1–9999. Update the app version before exceeding the range.')
    return str(number)

if __name__ == '__main__':
    number = compute(os.environ.get('PROJECT_BUILD_NUMBER', ''), os.environ.get('BUILD_NUMBER_OFFSET', '0'))
    path = Path(__file__).resolve().parents[1] / 'AutoDealerPro/Info.plist'
    info = plistlib.loads(path.read_bytes())
    info['CFBundleVersion'] = number
    path.write_bytes(plistlib.dumps(info))
    print('Apple build number:', number)
