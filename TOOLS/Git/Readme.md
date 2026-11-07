# README.md

```markdown
# dump_last_commits.sh

A small Bash script that dumps the **last N commits** from a Git repository — each commit's **title (subject)** and **comment (body)** — into a plain-text file. Useful for changelogs, release notes drafts, code-review summaries, or archiving recent history in a human-readable format.

---

## Features

- Extracts commit hash, author, date, title, and body.
- Works on the current repo or any repo path you specify.
- Configurable commit count and output filename.
- Validates input and fails cleanly if run outside a Git repo.
- Zero dependencies beyond `git` and Bash (3.2+).
- Readable, sectioned output.

---

## Requirements

- Bash 3.2 or newer
- Git

---

## Installation

1. Save the script as `dump_last_commits.sh`.
2. Make it executable:

   ```bash
   chmod +x dump_last_commits.sh
   ```

3. (Optional) Move it somewhere on your `PATH` so you can call it from anywhere:

   ```bash
   sudo mv dump_last_commits.sh /usr/local/bin/dump_last_commits
   ```

---

## Usage

```text
./dump_last_commits.sh [count] [output_file] [repo_path]
```

| Argument      | Default        | Description                                    |
| ------------- | -------------- | ---------------------------------------------- |
| `count`       | `10`           | Number of most-recent commits to export.       |
| `output_file` | `commits.txt`  | Path of the text file to write.                |
| `repo_path`   | `.`            | Path to the Git repository to read from.       |

All arguments are optional and positional.

### Examples

```bash
# Last 10 commits of the current repo -> commits.txt
./dump_last_commits.sh

# Last 25 commits of the current repo -> commits.txt
./dump_last_commits.sh 25

# Last 25 commits of the current repo -> out.txt
./dump_last_commits.sh 25 out.txt

# Last 5 commits of another repo -> out.txt
./dump_last_commits.sh 5 out.txt ~/projects/my-app
```

---

## Example output

`commits.txt`:

```text
========================================
Commit:  a1b2c3d
Author:  Jane Doe <jane@example.com>
Date:    2024-06-14 09:32:11
Title:   Fix null dereference in user loader
Comment:
Guard against missing profile record when the DB row is present
but the related object has been soft-deleted. Adds a regression test.

========================================
Commit:  e4f5g6h
Author:  John Smith <john@example.com>
Date:    2024-06-13 18:11:04
Title:   Bump dependencies
Comment:
```

---

## Exit codes

| Code | Meaning                                              |
| ---- | ---------------------------------------------------- |
| `0`  | Success                                              |
| `1`  | Invalid `count` argument                             |
| `1`  | `repo_path` does not exist or is not accessible      |
| `1`  | `repo_path` is not a Git repository                  |

---

## Customization

The commit format is controlled by the `--pretty=format:` string in the script. Common placeholders:

| Placeholder | Meaning              |
| ----------- | -------------------- |
| `%h`        | Short hash           |
| `%H`        | Full hash            |
| `%an`       | Author name          |
| `%ae`       | Author email         |
| `%ad`       | Author date          |
| `%s`        | Subject (title)      |
| `%b`        | Body (comment)       |
| `%B`        | Raw body (title+body)|

To exclude merge commits, add `--no-merges` to the `git log` call.

To grab just one commit's full message (subject + body), use:

```bash
git log -1 --pretty=%B
```

---

## License

MIT — free to use, modify, and distribute.
