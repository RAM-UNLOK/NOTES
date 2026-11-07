# Automated Log Analysis Scripts

Ready-to-run shell scripts and pipelines to split, filter, and report on Android logcat / kernel logs.

---

## Table of Contents

1. [Overview](#1-overview)
2. [split_logcat_errors.sh](#2-split_logcat_errorssh)
3. [Standalone Pipelines](#3-standalone-pipelines)
4. [avc_fix_generator.py](#4-avc_fix_generatorpy)
5. [Combined Diagnostic Script](#5-combined-diagnostic-script)
6. [Notes](#6-notes)

---

## 1. Overview

Logcat captures are noisy. These scripts reduce a 500 MB `full_logcat.log` into a handful of focused, greppable files:

| Script | Output | Purpose |
|---|---|---|
| `split_logcat_errors.sh` | 15+ categorised `.txt` files | Split one logcat into errors / crashes / SELinux / permissions |
| Inline pipelines | Single-purpose files | Frequency, priority distribution, unique AVC groups |
| `avc_fix_generator.py` | `.te` policy patches | Convert AVC denials into ready-to-apply SELinux rules |
| `full_diagnostic.sh` | Full dump + all categories | One-shot post-mortem capture |

Each section below is self-contained — copy the block you need.

---

## 2. `split_logcat_errors.sh`

Splits a single logcat file into categorized output files in the current directory.

### Usage

```bash
chmod +x split_logcat_errors.sh
./split_logcat_errors.sh logcat.log
```

If no argument is given, it defaults to `logcat.log` in the current directory.

### Full script

```bash
#!/usr/bin/env bash
#
# split_logcat_errors.sh
# Splits a single logcat file into categorised output files.
#
# Usage:
#   ./split_logcat_errors.sh [logcat_file]
#
# Default log file: logcat.log
#

set -u

LOGFILE="${1:-logcat.log}"

if [[ ! -f "$LOGFILE" ]]; then
    echo "[ERROR] File not found: $LOGFILE" >&2
    exit 1
fi

out() {
    echo "[*] $1 -> $2"
}

echo "[*] Splitting $LOGFILE ..."

# ── 1. Basic errors / fatals ──────────────────────────────────
grep -E " E | F " "$LOGFILE" > errors_fatals.txt
out "Errors and fatals" "errors_fatals.txt"

# ── 2. AndroidRuntime / FATAL EXCEPTION ───────────────────────
grep "AndroidRuntime"       "$LOGFILE" > androidruntime.txt
grep -n "FATAL EXCEPTION"   "$LOGFILE" > fatal_exception.txt
out "AndroidRuntime"        "androidruntime.txt"
out "FATAL EXCEPTION"       "fatal_exception.txt"

# ── 3. ANR / native crash / StrictMode / exceptions ───────────
grep -n "ANR in"         "$LOGFILE" > anr.txt
grep -n "Fatal signal"   "$LOGFILE" > native_crash_fatal_signal.txt
grep -n "StrictMode"     "$LOGFILE" > strictmode.txt
grep -n "Exception"      "$LOGFILE" > exception.txt
grep -n "java.lang."     "$LOGFILE" > java_lang.txt
out "ANR"                   "anr.txt"
out "Native crashes"        "native_crash_fatal_signal.txt"
out "StrictMode"            "strictmode.txt"
out "Exceptions"            "exception.txt"
out "java.lang.*"           "java_lang.txt"

# ── 4. SELinux AVC ────────────────────────────────────────────
grep "avc:"         "$LOGFILE" > avc_all.txt
grep "avc: denied"  "$LOGFILE" > avc_denied.txt
grep "avc: denied"  "$LOGFILE" \
    | grep -E "pid=|scontext=|tcontext=|tclass=" > avc_denied_compact.txt
out "All avc:"              "avc_all.txt"
out "avc: denied"           "avc_denied.txt"
out "avc: denied (compact)" "avc_denied_compact.txt"

# ── 5. Permission / security / access errors ─────────────────
grep -i "permission denied"           "$LOGFILE" > permission_denied.txt
grep -i "java.lang.SecurityException" "$LOGFILE" > java_securityexception.txt
grep -i "requires android.permission" "$LOGFILE" > requires_android_permission.txt
grep -i "SecurityException"           "$LOGFILE" > securityexception_any.txt
grep -i "Operation not permitted"     "$LOGFILE" > operation_not_permitted.txt
grep -i "EACCES"                      "$LOGFILE" > eacces.txt
out "permission denied"              "permission_denied.txt"
out "java.lang.SecurityException"    "java_securityexception.txt"
out "requires android.permission"    "requires_android_permission.txt"
out "SecurityException (any)"        "securityexception_any.txt"
out "Operation not permitted"        "operation_not_permitted.txt"
out "EACCES"                         "eacces.txt"

# ── 6. Combined security / SELinux ───────────────────────────
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" \
    "$LOGFILE" > security_selinux_combined.txt
out "Combined security/SELinux" "security_selinux_combined.txt"

echo "[*] Done."
```

### Output file reference

| File | Contents |
|---|---|
| `errors_fatals.txt` | Lines matching ` E ` or ` F ` priority markers |
| `androidruntime.txt` | Everything tagged `AndroidRuntime` |
| `fatal_exception.txt` | `FATAL EXCEPTION` headers (line-numbered) |
| `anr.txt` | `ANR in` markers |
| `native_crash_fatal_signal.txt` | `Fatal signal` entries |
| `strictmode.txt` | StrictMode violations |
| `exception.txt` | Any line containing `Exception` |
| `java_lang.txt` | `java.lang.*` references |
| `avc_all.txt` | Every `avc:` line (denied + permissive) |
| `avc_denied.txt` | Only `avc: denied` |
| `avc_denied_compact.txt` | `avc: denied` with context fields |
| `permission_denied.txt` | Case-insensitive `permission denied` |
| `java_securityexception.txt` | `java.lang.SecurityException` |
| `requires_android_permission.txt` | `requires android.permission` |
| `securityexception_any.txt` | Any `SecurityException` |
| `operation_not_permitted.txt` | `Operation not permitted` |
| `eacces.txt` | `EACCES` references |
| `security_selinux_combined.txt` | Union of the above security classes |

---

## 3. Standalone Pipelines

Copy-paste one-liners for specific analyses.

### 3.1 Error frequency by tag

```bash
grep " E " logcat.log | awk '{print $NF}' | sort | uniq -c | sort -rn > error_by_tag.log
```

### 3.2 Most frequent log messages

```bash
awk '{$1=$2=$3=$4=$5=""; print $0}' logcat.log \
    | sort | uniq -c | sort -rn | head -20 > frequent_logs.log
```

### 3.3 Spammy debug sources

```bash
grep " D " logcat.log | cut -d':' -f1 | sort | uniq -c | sort -rn | head -20 > spam_sources.log
```

### 3.4 Priority distribution

```bash
grep -o " [A-Z] " logcat.log | sort | uniq -c > priority_distribution.log
```

### 3.5 One log file per priority

```bash
for p in V D I W E F; do
    grep " $p " logcat.log > "logs_${p}.log"
done
```

### 3.6 Unique AVC denial groups

```bash
grep "avc: denied" logcat.log \
    | sed -E 's/.*scontext=([^ ]+) tcontext=([^ ]+) tclass=([^ ]+).*/\1 -> \2:\3/' \
    | sort -u > unique_avc_groups.txt
```

### 3.7 AVC denials ranked by target

```bash
grep "avc: denied" logcat.log \
    | grep -oE "tcontext=[^ ]+ tclass=[^ ]+" \
    | sort | uniq -c | sort -rn > avc_targets_ranked.txt
```

### 3.8 Unique raw AVC assertion bodies

```bash
grep "avc:" logcat.log | cut -d' ' -f3- | sort -u > sorted_avc_denials.txt
```

### 3.9 Crashes per process

```bash
grep -E "Process|Crash|died|signal" logcat.log > process_crashes.log
```

### 3.10 Filesystem errors

```bash
grep -E "ENOENT|EACCES|I/O error|filesystem" logcat.log > fs_errors.log
```

### 3.11 Property changes

```bash
grep "setprop\|ro\." logcat.log > property_changes.log
```

### 3.12 Top 10 tags by error count

```bash
grep -E " E | F " logcat.log \
    | awk '{print $6}' \
    | sort | uniq -c | sort -rn | head -10 > top_error_tags.log
```

### 3.13 Extract FATAL EXCEPTION blocks (header + 30 lines)

```bash
awk '/FATAL EXCEPTION/{flag=1; count=0} flag && count++<30 {print} count>=30 {flag=0}' \
    logcat.log > fatal_exception_blocks.log
```

### 3.14 Extract AVC denials with full context (2 lines before, 2 after)

```bash
grep -B 2 -A 2 "avc: denied" logcat.log > avc_with_context.log
```

### 3.15 Extract all issues from an existing log (single command)

```bash
INPUT="live_boot_debug.log" && \
grep " E " "$INPUT" > errors.log && \
grep "avc:" "$INPUT" > sepolicy.log && \
grep -E "ANR|crash|FATAL" "$INPUT" > crashes.log && \
grep -E "Exception" "$INPUT" > exceptions.log && \
echo "Analysis complete: errors.log, sepolicy.log, crashes.log, exceptions.log"
```

---

## 4. `avc_fix_generator.py`

Converts parsed AVC denials into modern (Android 12+) SELinux `.te` policy patches.

The full script and usage instructions live in **`02-selinux-avc-debugging.md` → Section 5**. A minimal wrapper is shown here for convenience.

### Quick usage

```bash
python3 avc_fix_generator.py full_logcat.log
```

### Outputs

- `avc_denial_report.txt` — human-readable, grouped by target `.te` file
- `te_patches/<domain>.te` — ready-to-paste snippets
- `summary_table.txt` — one-row-per-denial quick reference

### Suggested pipeline (split → generate)

```bash
# 1. Extract AVC denials from a large logcat
grep "avc: denied" full_logcat.log > avc_only.log

# 2. Generate patches
python3 avc_fix_generator.py avc_only.log

# 3. Inspect outputs
cat avc_denial_report.txt
cat summary_table.txt
ls  te_patches/
```

### When NOT to use the generator

- The log contains **permissive** denials only (`permissive=1`) — the generator only looks for `denied`.
- Your ROM uses a **different macro set** (pre-Android 12 `unix_socket_connect`, `r_dir_file`, etc.) — use the generated rules as raw `allow` statements.
- The denial is on a **generic `proc` / `sysfs`** type — the generator flags these with a `AVOID generic` note; fix the `genfscon` label instead of adding a rule.

---

## 5. Combined Diagnostic Script

A single script that captures a fresh logcat + kernel log and runs the full split pipeline. Useful for post-mortem analysis or filing bug reports.

### Save as `full_diagnostic.sh`

```bash
#!/usr/bin/env bash
#
# full_diagnostic.sh
# Capture everything relevant to a bug report in one shot.
#
# Usage:
#   ./full_diagnostic.sh [output_dir]
#
# Default output dir: diagnostic_<timestamp>/
#

set -u

OUT="${1:-diagnostic_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT" || { echo "[ERROR] Cannot create $OUT" >&2; exit 1; }
cd "$OUT" || exit 1

echo "[*] Output dir: $OUT"

# ── 1. Kernel + pstore ────────────────────────────────────────
echo "[*] Capturing kernel logs..."
adb shell dmesg > dmesg.log 2>&1 || echo "[WARN] dmesg failed"
adb shell cat /sys/fs/pstore/console-ramoops-0 > ramoops.log 2>&1 \
    || echo "[WARN] ramoops failed"
adb shell cat /proc/last_kmsg > last_kmsg.log 2>&1 \
    || echo "[WARN] last_kmsg failed (older kernels only)"

# ── 2. Tombstones ─────────────────────────────────────────────
echo "[*] Pulling tombstones..."
adb pull /data/tombstones/ ./tombstones/ >/dev/null 2>&1 \
    || echo "[WARN] tombstones not accessible (need adb root)"

# ── 3. Full logcat ────────────────────────────────────────────
echo "[*] Capturing logcat..."
adb logcat -b all -d > full_logcat.log 2>&1 || echo "[WARN] logcat failed"

# ── 4. Split categories ───────────────────────────────────────
echo "[*] Splitting logcat..."
grep -E " E | F "          full_logcat.log > errors_fatals.txt
grep "AndroidRuntime"      full_logcat.log > androidruntime.txt
grep -n "FATAL EXCEPTION"  full_logcat.log > fatal_exception.txt
grep -n "ANR in"           full_logcat.log > anr.txt
grep -n "Fatal signal"     full_logcat.log > native_crash.txt
grep "avc: denied"         full_logcat.log > avc_denied.txt
grep "avc:"                full_logcat.log > avc_all.txt
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" \
    full_logcat.log > security_combined.txt

# ── 5. Summary ────────────────────────────────────────────────
echo ""
echo "[+] Summary:"
for f in errors_fatals.txt androidruntime.txt fatal_exception.txt \
         anr.txt native_crash.txt avc_denied.txt avc_all.txt security_combined.txt; do
    printf "    %-28s %6d lines\n" "$f" "$(wc -l < "$f")"
done

echo ""
echo "[+] Done. Package for upload:"
echo "    tar czf ${OUT}.tar.gz $OUT/"
```

### Usage

```bash
chmod +x full_diagnostic.sh
./full_diagnostic.sh
# → diagnostic_20260101_120000/
#   dmesg.log, ramoops.log, last_kmsg.log
#   full_logcat.log
#   errors_fatals.txt, androidruntime.txt, ...
#   tombstones/
```

### Variant — device monitoring with interactive stop

```bash
echo "Starting device monitoring..." && \
adb logcat -c && \
adb logcat -v threadtime > monitor_$(date +%Y%m%d_%H%M%S).log & \
LOGCAT_PID=$! && \
echo "Press Enter to stop monitoring..." && \
read && \
kill $LOGCAT_PID && \
echo "Monitoring complete"
```

---

## 6. Notes

- All scripts use `set -u` (error on undefined variables). `grep` returns non-zero when it finds nothing, which is expected — the scripts do not `set -e` to avoid aborting on empty categories.
- `grep` output for categories with zero matches is an empty file — that is a valid, useful result (e.g. `avc_denied.txt` being empty means no SELinux denials).
- `adb logcat -d` in the combined script **dumps the current buffer and exits** (no infinite stream), which is what you want for offline analysis.
- The `full_diagnostic.sh` script needs `adb root` for `/data/tombstones/` and `/sys/fs/pstore/`. Run it on a **userdebug** or **eng** build; on a `user` build these will be skipped with a `[WARN]`.
- The `avc_fix_generator.py` full script lives in `02-selinux-avc-debugging.md`. Keeping a separate copy in the current directory is fine — just ensure you're running the newer of the two.
- For interactive logcat filtering (live capture with grep, priority filtering, buffer management), see `01-adb-logcat-debugging.md`.
- For deeper SELinux AVC analysis and rule translation, see `02-selinux-avc-debugging.md`.

---

## Appendix — Full Document Set

| File | Topic |
|---|---|
| `01-adb-logcat-debugging.md` | Logcat capture, filtering, buffers, formats |
| `02-selinux-avc-debugging.md` | AVC parsing, macros, `.te` generation |
| `03-android-audio-hal-vendor-debug.md` | Audio HAL, dlopen, readelf, strace |
| `04-repo-workspace-reset.md` | `repo forall` reset, git clean, force-sync |
| `05-rom-build-fixes.md` | zipalign, presigned APKs, dex2oat, hidden-API |
| `06-log-analysis-scripts.md` | Split scripts, pipelines, diagnostic capture |
