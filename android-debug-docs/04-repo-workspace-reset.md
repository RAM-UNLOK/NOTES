# Repo & Git Workspace Reset

Wipe local changes, untracked files, and misaligned branches across every sub-repository managed by the `repo` tool — returning the workspace to a clean state that matches the manifest.

---

## Table of Contents

1. [Overview](#1-overview)
2. [The Three-Command Reset](#2-the-three-command-reset)
3. [Step-by-Step Breakdown](#3-step-by-step-breakdown)
4. [One-Shot Reset](#4-one-shot-reset)
5. [Flag Reference](#5-flag-reference)
6. [Safety & Recovery](#6-safety--recovery)
7. [Scenarios](#7-scenarios)
8. [Notes](#8-notes)

---

## 1. Overview

A `repo` workspace is a collection of many git repositories cloned side-by-side. To fully reset it you need to clean **three layers**:

| Layer | What it holds | Command to clean it |
|---|---|---|
| Tracked files | Modified/deleted files in each project | `git reset --hard` |
| Untracked files | New files + ignored build artifacts | `git clean -fdx` |
| Branch alignment | Detached HEADs, local branches diverging from manifest | `repo sync -c -d --force-sync` |

Running all three returns every sub-project to the exact state declared in the manifest.

> ⚠️ **Destructive.** All uncommitted work is lost. Stash or back up anything you care about before running.

---

## 2. The Three-Command Reset

```bash
# 1. Discard tracked modifications in every project
repo forall -vc "git reset --hard"

# 2. Nuke untracked files, untracked directories, and ignored files
repo forall -vc "git clean -fdx"

# 3. Sync and force-align every project to the manifest revision
repo sync -c -d --force-sync
```

Order matters — run them exactly in this sequence.

---

## 3. Step-by-Step Breakdown

### Step 1 — Discard all tracked modifications

```bash
repo forall -vc "git reset --hard"
```

- Runs `git reset --hard` inside **every** project tracked by `repo`.
- Resets each project's working tree and index to the **current HEAD** commit.
- Leaves untracked files untouched (Step 2 handles those).
- Leaves branch pointers untouched — if a project is on a local branch that diverged from the manifest, that divergence is preserved here.

**What this removes:**
- Modified files
- Staged changes
- Locally deleted files (restored from HEAD)

**What this leaves:**
- Untracked files
- Ignored build artifacts
- Local branch divergences

### Step 2 — Nuke untracked files and directories

```bash
repo forall -vc "git clean -fdx"
```

- Runs `git clean -fdx` inside every project.
- `-f` — force (git clean requires it)
- `-d` — recurse into untracked directories
- `-x` — also delete files matched by `.gitignore` (build outputs, `*.o`, `out/`, `dist/`)

**What this removes:**
- Newly created source files that were never `git add`-ed
- Full untracked directories
- Build artifacts, object files, generated sources

**Preview before running (recommended):**

```bash
repo forall -vc "git clean -ndx"
```

`-n` = dry-run. It prints what would be deleted without deleting anything. Run this first if you're unsure.

### Step 3 — Sync and force-align to the manifest

```bash
repo sync -c -d --force-sync
```

- `-c` — fetch only the branch specified in the manifest (current branch on each project)
- `-d` — detach HEAD to the manifest revision; throws away local branch pointers that diverge from the manifest
- `--force-sync` — overwrite conflicting git objects (e.g. after a previous interrupted sync)

**What this fixes:**
- Detached HEAD projects stuck on old commits → fast-forwarded to manifest
- Local branches diverging from the manifest → detached to the manifest revision
- Corrupted or half-synced git objects → overwritten

---

## 4. One-Shot Reset

Chain all three into a single line for a full clean state:

```bash
repo forall -vc "git reset --hard" && \
repo forall -vc "git clean -fdx" && \
repo sync -c -d --force-sync
```

Or as a reusable shell function (add to `~/.bashrc`):

```bash
repo_reset() {
    echo "[*] Discarding tracked changes..."
    repo forall -vc "git reset --hard" || return 1

    echo "[*] Removing untracked files..."
    repo forall -vc "git clean -fdx" || return 1

    echo "[*] Syncing to manifest..."
    repo sync -c -d --force-sync || return 1

    echo "[+] Workspace reset to manifest state."
}
```

Then just run:

```bash
repo_reset
```

---

## 5. Flag Reference

### `repo` flags

| Flag | Meaning |
|---|---|
| `repo forall -c "<cmd>"` | Run `<cmd>` inside every project |
| `repo forall -v` | Verbose — print each project name before running |
| `repo forall -p` | Show the project path before running |
| `repo forall -e` | Execute `<cmd>` in a single shell (useful for env exports) |
| `repo sync -c` | Fetch only the current branch |
| `repo sync -d` | Detach HEAD to the manifest revision |
| `repo sync --force-sync` | Overwrite conflicting git objects |
| `repo sync -j<N>` | Parallel jobs (e.g. `-j8`) |

### `git reset` flags

| Flag | Meaning |
|---|---|
| `--hard` | Reset working tree and index to target; discard all tracked changes |
| `--soft` | Only move HEAD; leave working tree and index untouched |
| `--mixed` | (default) Move HEAD and reset index; keep working tree |
| `--merge` | Keep local changes where possible; abort if conflict |

### `git clean` flags

| Flag | Meaning |
|---|---|
| `-f` | Force — required unless `clean.requireForce=false` |
| `-d` | Include untracked directories |
| `-x` | Include ignored files (`.gitignore`d) |
| `-X` | Remove **only** ignored files (inverse of `-x`) |
| `-n` | Dry-run — show what would be deleted |
| `-i` | Interactive prompt per file |

---

## 6. Safety & Recovery

### Back up uncommitted work first (recommended)

```bash
# Stash everything in every project (including untracked files)
repo forall -vc "git stash push -u -m 'pre-reset backup'"

# List what was stashed
repo forall -vc "git stash list"
```

To restore after reset, if you realise something was needed:

```bash
repo forall -vc "git stash pop"
```

### Preview before deleting (dry-run)

```bash
# See what git clean would remove
repo forall -vc "git clean -ndx"

# See which projects have uncommitted changes
repo forall -vc "git status --short" | grep -v '^$'

# See which projects are on detached branches
repo forall -vc "git branch --show-current"

# See which projects diverge from manifest
repo forall -vc "git log --oneline @{u}..HEAD 2>/dev/null"
```

### Back up the whole workspace (heavyweight)

If the workspace has significant uncommitted work, prefer:

```bash
# Archive every project's working tree including untracked files
mkdir -p ~/repo_backup
repo forall -c 'mkdir -p ~/repo_backup/$(dirname $REPO_PATH) && \
    tar czf ~/repo_backup/$REPO_PATH.tar.gz .'
```

(`$REPO_PATH` is set by `repo forall` inside each project.)

---

## 7. Scenarios

### "I want to just see what's dirty"
```bash
repo forall -vc "git status --short" | grep -v '^$'
```

### "I modified a few files and want them gone"
```bash
repo forall -vc "git reset --hard"
```

### "I created new files I don't want anymore"
```bash
repo forall -vc "git clean -fdx"
```
Or safer, dry-run first:
```bash
repo forall -vc "git clean -ndx"
```

### "My sync is failing with 'conflicting objects'"
```bash
repo sync --force-sync
```

### "Some projects are stuck on detached HEAD or wrong branches"
```bash
repo sync -c -d --force-sync
```

### "Everything is broken, give me a factory-fresh workspace"
```bash
repo forall -vc "git reset --hard"  && \
repo forall -vc "git clean -fdx"    && \
repo sync -c -d --force-sync
```

### "I want to preserve one project while resetting the rest"
```bash
# Reset all, then re-apply the changes in one project
repo forall -vc "git reset --hard" && \
repo forall -vc "git clean -fdx"   && \
repo sync -c -d --force-sync

# Then manually recover your preserved project from a stash or backup
cd path/to/preserved/project
git stash pop   # if you stashed beforehand
```

### "I only want to reset a single project"
```bash
cd path/to/project
git reset --hard
git clean -fdx
# no repo sync needed — just this project is reset
```

---

## 8. Notes

- **Order matters.** `git reset` before `git clean` so that `clean` runs on the freshly reset tree.
- **`-d` in `repo sync` detaches HEAD.** If you were intentionally working on a local branch that isn't in the manifest, you will lose the branch pointer (though the commits still exist in the object DB and can be recovered via `git reflog`).
- **`--force-sync` is the nuclear option for sync.** Prefer a plain `repo sync` unless you're hitting `error.GitError` from conflicting objects.
- **`git clean -fdx` deletes build outputs.** Expect a full rebuild after running it (`out/` in an AOSP tree can be tens of GB).
- **`repo forall -v` is worth it.** On large workspaces it prints each project name so you can see progress and spot a hung project.
- **On Windows + Cygwin/WSL,** `repo` works fine but `git clean -fdx` may hit long-path limits — use native Linux for large AOSP trees.
- **Verify after reset:**
  ```bash
  repo status                         # should be clean
  repo forall -vc "git status --short" | grep -v '^$'   # should be empty
  ```

---

**TL;DR**

```bash
repo forall -vc "git reset --hard" && \
repo forall -vc "git clean -fdx" && \
repo sync -c -d --force-sync
```
