#!/usr/bin/env python3
"""Enable the signed workflow after the owner supplies a registered Bundle ID.
The integration name is a label in Codemagic, never an API key or password.
"""
import argparse
import json
import re
from pathlib import Path

def configure(root, bundle_id, integration):
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9-]+){2,}', bundle_id) or bundle_id.startswith('com.example.'):
        raise ValueError('Supply your real, registered Apple Bundle ID; com.example is not a release identity.')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9 _-]{0,63}', integration):
        raise ValueError('Integration name must be a 1–64 character label, not a secret.')
    project = root / 'AutoDealerPro.xcodeproj/project.pbxproj'
    text = project.read_text()
    def replace(match):
        suffix = '.tests' if match.group(1).endswith('.tests') else ''
        return 'PRODUCT_BUNDLE_IDENTIFIER = "' + bundle_id + suffix + '";'
    text, count = re.subn(r'PRODUCT_BUNDLE_IDENTIFIER = "([^"]+)";', replace, text)
    if count != 4:
        raise ValueError('Unexpected Xcode target configuration; no changes made.')
    workflow = (root / 'config/testflight-workflow.yaml.template').read_text()
    workflow = workflow.replace('__BUNDLE_ID__', json.dumps(bundle_id)).replace('__INTEGRATION__', json.dumps(integration))
    config = root / 'codemagic.yaml'
    baseline = config.read_text().split('\n  ios-testflight:', 1)[0].rstrip()
    project.write_text(text)
    config.write_text(baseline + '\n' + workflow)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bundle-id', required=True)
    parser.add_argument('--integration', required=True)
    args = parser.parse_args()
    configure(Path(__file__).resolve().parents[1], args.bundle_id, args.integration)
    print('Internal TestFlight workflow configured. Signing files and the App Store Connect integration must exist in Codemagic before running it.')
