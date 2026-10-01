#!/usr/bin/env python3
"""Dependency-free structural checks. This is not a Swift compiler."""
import json
import plistlib
import re
import struct
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for pattern in ('*.plist', '*.xcprivacy'):
    for path in root.glob('AutoDealerPro/' + pattern):
        plistlib.loads(path.read_bytes())
for path in (root / 'AutoDealerPro/Assets.xcassets').rglob('*.json'):
    json.loads(path.read_text())
for path in (root / 'AutoDealerPro.xcodeproj').rglob('*.xcscheme'):
    ET.parse(path)
project = (root / 'AutoDealerPro.xcodeproj/project.pbxproj').read_text()
ids = re.findall(r'^\s*([A-F0-9]{24}) = \{', project, re.M)
assert len(ids) == len(set(ids)), 'Duplicate Xcode object IDs'
assert set(re.findall(r'\b[A-F0-9]{24}\b', project)) == set(ids), 'Unresolved project object'
for path in (root / 'AutoDealerPro').glob('*.swift'):
    assert 'path = "' + path.name + '"' in project, f'Missing source: {path.name}'
icon = (root / 'AutoDealerPro/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
assert icon[:8] == b'\x89PNG\r\n\x1a\n', 'Invalid PNG icon'
width, height, depth, color_type = struct.unpack('>IIBB', icon[16:26])
assert (width, height) == (1024, 1024) and color_type == 2, 'Icon must be opaque RGB 1024x1024'
info = plistlib.loads((root / 'AutoDealerPro/Info.plist').read_bytes())
assert info['NSCameraUsageDescription']
assert info['CFBundleIdentifier'] == '$(PRODUCT_BUNDLE_IDENTIFIER)'
print(f'PASS: {len(ids)} project objects, sources, plist/JSON/XML and app icon.')
print('Swift compilation and XCTest are separate steps; this check does not claim they passed.')
