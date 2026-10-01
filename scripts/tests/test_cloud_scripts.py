import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / (name + '.py'))
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod
select = module('select-simulator').select
compute = module('set-build-number').compute
configure = module('configure-testflight').configure

class CloudTests(unittest.TestCase):
    def test_select_available_iphone_on_latest_runtime(self):
        data = {'devices': {
            'com.apple.CoreSimulator.SimRuntime.iOS-17-5': [{'name':'iPhone 15','udid':'old','isAvailable':True}],
            'com.apple.CoreSimulator.SimRuntime.iOS-26-0': [{'name':'iPhone 17','udid':'new','isAvailable':True},{'name':'iPhone 17 Pro','udid':'bad','isAvailable':False},{'name':'iPad Pro','udid':'ipad','isAvailable':True}],
            'com.apple.CoreSimulator.SimRuntime.tvOS-26-0': [{'name':'Apple TV','udid':'tv','isAvailable':True}]
        }}
        self.assertEqual(select(data), 'new')
        self.assertEqual(select({'devices':{}}), '')
    def test_build_number_monotonic_and_validated(self):
        self.assertEqual(compute('12','100'), '112')
        self.assertEqual(compute('13','100'), '113')
        for seq, offset in [('','0'), ('abc','0'), ('1','-5'), ('9999','1'), ('0','0')]:
            with self.assertRaises(ValueError): compute(seq,offset)
    def test_testflight_config_is_idempotent_and_has_no_public_release(self):
        with tempfile.TemporaryDirectory() as d:
            dest=Path(d)
            project=ROOT.parent
            for name in ['AutoDealerPro.xcodeproj','config']:
                shutil.copytree(project/name,dest/name)
            shutil.copy2(project/'codemagic.yaml',dest/'codemagic.yaml')
            configure(dest,'de.testdealer.inventory','Apple Integration')
            first=(dest/'codemagic.yaml').read_text()
            configure(dest,'de.testdealer.inventory','Apple Integration')
            self.assertEqual(first,(dest/'codemagic.yaml').read_text())
            self.assertEqual(first.count('\n  ios-testflight:'),1)
            self.assertIn('submit_to_app_store: false',first)
            self.assertIn('testFlightInternalTestingOnly',first)
            self.assertNotIn('__BUNDLE_ID__',first)
            pbx=(dest/'AutoDealerPro.xcodeproj/project.pbxproj').read_text()
            self.assertNotIn('com.example.autodealerpro',pbx)
            self.assertEqual(pbx.count('"de.testdealer.inventory.tests"'),2)
            with self.assertRaises(ValueError): configure(dest,'com.example.placeholder','Apple')
            with self.assertRaises(ValueError): configure(dest,'de.testdealer.inventory','\nsecret')

if __name__ == '__main__': unittest.main()
