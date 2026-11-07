#!/usr/bin/env bash
#
# dump_last_commits.sh
#
# Write the last N commits' titles (subjects) and comments (bodies)
# to a plain-text file.
#
# Usage:
#   ./dump_last_commits.sh [count] [output_file] [repo_path]
#
# Examples:
#   ./dump_last_commits.sh                    # last 10 commits -> commits.txt
#   ./dump_last_commits.sh 25                 # last 25 commits -> commits.txt
#   ./dump_last_commits.sh 25 out.txt         # last 25 commits -> out.txt
#   ./dump_last_commits.sh 5 out.txt ~/repo   # run against another repo

set -euo pipefail

COUNT="${1:-10}"
OUTPUT="${2:-commits.txt}"
REPO="${3:-.}"

# --- Validate the count argument -------------------------------------------
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
  echo "Error: count must be a positive integer (got: '$COUNT')" >&2
  exit 1
fi

# --- Make sure we're in a git repo -----------------------------------------
cd "$REPO" 2>/dev/null || { echo "Error: cannot cd to '$REPO'" >&2; exit 1; }

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not a git repository: $(pwd)" >&2
  exit 1
fi

# --- Write the file --------------------------------------------------------
: > "$OUTPUT"

git log -n "$COUNT" \
  --date=format:'%Y-%m-%d %H:%M:%S' \
  --pretty=format:'========================================%nCommit:  %h%nAuthor:  %an <%ae>%nDate:    %ad%nTitle:   %s%nComment:%n%b%n' \
  >> "$OUTPUT"

# Ensure the file ends with a newline
printf '\n' >> "$OUTPUT"

echo "Wrote last $COUNT commit(s) to: $OUTPUT"