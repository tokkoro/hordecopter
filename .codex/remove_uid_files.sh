#!/usr/bin/env bash
###############################################################
# .codex/remove_uid_files.sh
# Key Classes      • N/A
# Key Functions    • remove_uid_files() – deletes *.uid artifacts
#                 • strip_uid_fields() – removes uid fields from text assets
# Critical Consts  • UID_GLOB – file patterns scanned for uid fields
# Editor Exports   • N/A
# Dependencies     • python3, find, rg
# Last Major Rev   • 25-03-09 – add UID cleanup for repo hygiene
###############################################################
set -euo pipefail

UID_GLOB=("*.tscn" "*.tres" "*.godot")

stage_changes=false
if [[ "${1:-}" == "--stage" ]]; then
	stage_changes=true
fi

remove_uid_files() {
	local uid_files
	uid_files=$(find . -name "*.uid" -type f)
	if [[ -n "$uid_files" ]]; then
		echo "🧹 Removing .uid files"
		rm -f $uid_files
	fi
}

strip_uid_fields() {
	python3 - <<'PY'
from pathlib import Path
import re

globs = ["*.tscn", "*.tres", "*.godot"]
for pattern in globs:
	for path in Path(".").rglob(pattern):
		if not path.is_file():
			continue
		text = path.read_text(encoding="utf-8")
		if "uid://" not in text:
			continue
		lines = []
		changed = False
		for line in text.splitlines():
			if line.lstrip().startswith('uid="uid://'):
				changed = True
				continue
			new_line = re.sub(r' uid="uid://[^"]+"', "", line)
			if new_line != line:
				changed = True
			lines.append(new_line)
		if changed:
			path.write_text("\n".join(lines) + ("\n" if text.endswith("\n") else ""), encoding="utf-8")
PY
}

validate_no_uid_refs() {
	if rg -n "uid://|\\buid=\\\"uid://" --glob "!*.import" --glob "!.pre-commit-config.yaml" --glob "!.codex/remove_uid_files.sh" .; then
		echo "🛑 UID references found outside .import files. Remove uid fields before committing."
		exit 1
	fi
}

remove_uid_files
strip_uid_fields
validate_no_uid_refs

if $stage_changes; then
	git add -u
fi
