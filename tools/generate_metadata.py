#!/usr/bin/env python3
"""Generate Plasma 6 metadata.json from the canonical metadata.desktop."""

from __future__ import annotations

import configparser
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "package" / "metadata.desktop"
TARGET = ROOT / "package" / "metadata.json"


def require(section: configparser.SectionProxy, key: str) -> str:
    value = section.get(key, "").strip()
    if not value:
        raise SystemExit(f"metadata.desktop is missing {key}")
    return value


def localized_values(
    section: configparser.SectionProxy,
    desktop_key: str,
    json_key: str,
) -> dict[str, str]:
    values = {json_key: require(section, desktop_key)}
    prefix = f"{desktop_key}["
    for key, value in section.items():
        if key.startswith(prefix) and key.endswith("]"):
            locale = key[len(prefix) : -1]
            values[f"{json_key}[{locale}]"] = value
    return values


def main() -> None:
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    with SOURCE.open(encoding="utf-8") as source_file:
        parser.read_file(source_file)

    section = parser["Desktop Entry"]
    plugin: dict[str, object] = {
        "Authors": [
            {
                "Email": require(section, "X-KDE-PluginInfo-Email"),
                "Name": require(section, "X-KDE-PluginInfo-Author"),
            }
        ],
        "Category": require(section, "X-KDE-PluginInfo-Category"),
        "Icon": require(section, "Icon"),
        "Id": require(section, "X-KDE-PluginInfo-Name"),
        "License": require(section, "X-KDE-PluginInfo-License"),
        "Version": require(section, "X-KDE-PluginInfo-Version"),
        "Website": require(section, "X-KDE-PluginInfo-Website"),
    }
    plugin.update(localized_values(section, "Name", "Name"))
    plugin.update(localized_values(section, "Comment", "Description"))

    metadata = {
        "KPlugin": plugin,
        "KPackageStructure": require(section, "X-KDE-ServiceTypes"),
        "X-Plasma-API-Minimum-Version": require(
            section, "X-Plasma-API-Minimum-Version"
        ),
        "X-Plasma-Provides": [
            item.strip()
            for item in require(section, "X-Plasma-Provides").split(",")
            if item.strip()
        ],
    }

    temporary_target = TARGET.with_suffix(".json.tmp")
    temporary_target.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary_target.replace(TARGET)


if __name__ == "__main__":
    main()
