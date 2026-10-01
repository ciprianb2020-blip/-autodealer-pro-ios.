#!/usr/bin/env python3
"""Select an available iPhone on the newest installed iOS runtime."""
import json
import re
import sys

def select(payload):
    candidates = []
    for runtime, devices in payload.get("devices", {}).items():
        match = re.search(r"iOS-(\d+)-(\d+)(?:-(\d+))?$", runtime)
        if not match:
            continue
        version = tuple(int(n or 0) for n in match.groups())
        for device in devices:
            if device.get("isAvailable", True) and device.get("name", "").startswith("iPhone"):
                candidates.append((version, device["name"], device["udid"]))
    return max(candidates)[2] if candidates else ""

if __name__ == "__main__":
    print(select(json.load(sys.stdin)))
