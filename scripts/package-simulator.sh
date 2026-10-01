#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app_path=".build/Build/Products/Debug-iphonesimulator/AutoDealerPro.app"
if [ ! -d "$app_path" ]; then
  echo "Simulator app missing: compilation must succeed first."
  exit 1
fi
mkdir -p build
ditto -c -k --sequesterRsrc --keepParent "$app_path" build/AutoDealerPro-Simulator.zip
python3 - <<'PY'
from pathlib import Path
import zipfile
bundles = sorted(Path('.build').glob('TestResults-*.xcresult'))
if not bundles:
    raise SystemExit('XCTest result bundle missing.')
with zipfile.ZipFile('build/XCTest-Results.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for bundle in bundles:
        for path in bundle.rglob('*'):
            if path.is_file():
                archive.write(path, path.relative_to('.build'))
print('Simulator app and XCTest results packaged. These files do not install on an iPhone.')
PY
