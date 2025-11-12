#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Categorize Brew packages")
    parser.add_argument("--manifest", required=True, help="Path to categories.json manifest")
    parser.add_argument("--type", choices=["formulae", "casks"], required=True, help="Item type to categorize")
    parser.add_argument(
        "--format",
        choices=["human", "brew"],
        default="human",
        help="Output format (human-readable or Brewfile snippet)",
    )
    parser.add_argument(
        "--label-uncategorized",
        action="store_true",
        help="Whether to include an Uncategorized section (only used in human format)",
    )
    return parser.parse_args()


def load_manifest(path: Path) -> dict:
    try:
        with path.open() as fh:
            return json.load(fh)
    except FileNotFoundError as exc:
        raise SystemExit(f"Manifest not found: {path}") from exc


def matches(match_spec: dict, item: str) -> bool:
    if any(item == exact for exact in match_spec.get("exact", [])):
        return True
    if any(item.startswith(prefix) for prefix in match_spec.get("prefix", [])):
        return True
    for pattern in match_spec.get("regex", []):
        if re.search(pattern, item):
            return True
    return False


def categorize(items, categories):
    assigned = set()
    sections = []
    for category in categories:
        match_spec = category.get("match", {})
        matched = [item for item in items if item not in assigned and matches(match_spec, item)]
        if matched:
            sections.append((category.get("title", category.get("id", "Unknown")), matched))
            assigned.update(matched)
    remaining = [item for item in items if item not in assigned]
    return sections, remaining


def emit_human(sections, remaining, show_uncategorized: bool):
    for title, rows in sections:
        print(f"=== {title} ===")
        print("\n".join(rows) if rows else "")
        print()
    if show_uncategorized:
        print("=== Uncategorized ===")
        print("\n".join(remaining) if remaining else "")


def emit_brew(sections, item_type):
    keyword = "brew" if item_type == "formulae" else "cask"
    for title, rows in sections:
        if not rows:
            continue
        print(f"# {title}")
        for row in rows:
            print(f'{keyword} "{row}"')
        print()


def main():
    args = parse_args()
    manifest = load_manifest(Path(args.manifest))
    items = [line.strip() for line in sys.stdin if line.strip()]
    categories = manifest.get(args.type, [])
    sections, remaining = categorize(items, categories)

    if args.format == "human":
        emit_human(sections, remaining, args.label_uncategorized)
    else:
        emit_brew(sections, remaining, args.type)


if __name__ == "__main__":
    main()
