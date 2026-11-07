# ADB Logcat Debugging Guide

Complete reference for capturing, filtering, and analyzing Android logcat output.

---

## Table of Contents

1. [Basic Log Capture](#1-basic-log-capture)
2. [Log Priority Filtering](#2-log-priority-filtering)
3. [Buffer Management](#3-buffer-management)
4. [Process & Package Filtering](#4-process--package-filtering)
5. [Error / Crash Extraction](#5-error--crash-extraction)
6. [ANR, StrictMode & Hangs](#6-anr-strictmode--hangs)
7. [SELinux & Permission Errors](#7-selinux--permission-errors)
8. [Performance & Memory](#8-performance--memory)
9. [Network & Connectivity](#9-network--connectivity)
10. [Boot & Init](#10-boot--init)
11. [Real-Time Monitoring](#11-real-time-monitoring)
12. [Output Formats](#12-output-formats)
13. [Statistics & Analysis](#13-statistics--analysis)
14. [File Operations](#14-file-operations)
15. [Background Capture](#15-background-capture)
16. [Quick Recipes](#16-quick-recipes)
17. [Notes](#17-notes)

---

## 1. Basic Log Capture

### Capture all logs to a file
```bash
adb logcat > live_boot_debug.log
```

### Capture and display simultaneously
```bash
adb logcat | tee live_boot_debug.log
```

### Capture all buffers (main, system, events, crash)
```bash
adb logcat -b all > full_logcat.log
adb logcat -b all > full_logcat1.log   # second capture (e.g. after reboot)
```

### Capture with timestamps / threadtime
```bash
adb logcat -v time       > logcat_with_time.log
adb logcat -v threadtime > logcat_threadtime.log
```

### Clear previous logs, then capture fresh
```bash
adb logcat -c && adb logcat > fresh_debug.log
```

### Auto-timestamped filename
```bash
adb logcat > "logcat_$(date +%Y%m%d_%H%M%S).log"
```

### Capture, save, and filter in one pass
```bash
adb logcat 2>&1 | tee capture.log | grep -i error
```

---

## 2. Log Priority Filtering

| Command | Result |
|---|---|
| `adb logcat "*:E"` | Errors only |
| `adb logcat "*:W"` | Warnings and above |
| `adb logcat "*:I"` | Info and above |
| `adb logcat "*:D"` | Debug logs |
| `adb logcat "SystemServer:E" "ActivityManager:D"` | Mixed per-tag priority |

```bash
adb logcat "*:E" > errors.log
adb logcat "*:W" > warnings_and_above.log
adb logcat "*:D" > debug_logs.log
adb logcat "*:I" > info_and_above.log
adb logcat "SystemServer:E" "ActivityManager:D" > mixed_priority.log
```

---

## 3. Buffer Management

```bash
adb logcat -g                    # show buffer sizes
adb logcat -G 16M                # increase buffer to 16 MB
adb logcat -b main   > main.log
adb logcat -b system > system.log
adb logcat -b events > events.log
adb logcat -b crash  > crash.log
adb logcat -b main -b system -b crash > all_buffers.log
adb shell cat /proc/kmsg > kernel_messages.log
```

---

## 4. Process & Package Filtering

```bash
# Find PID
adb shell pidof com.package.name

# Filter live output by PID
adb logcat --pid=<PID> > app_specific.log

# By package name (live)
adb logcat | grep "com.package.name" | tee app_debug.log

# By package name (offline log)
grep -E "com.package1|com.package2" live_boot_debug.log > multi_app_debug.log

# System service logs
grep -E "SystemServiceManager|ServiceManager" live_boot_debug.log > system_services.log

# App logs that are ALSO errors / crashes
PKG="com.example.app"
grep -n "$PKG" logcat.log | egrep "E |F |FATAL EXCEPTION|ANR in|Fatal signal"

# Everything for a PID, filtered to serious problems
PID=1234
grep -n " $PID " logcat.log | egrep "E |F |FATAL EXCEPTION|ANR in|Fatal signal"
```

---

## 5. Error / Crash Extraction

```bash
# ERROR and FATAL lines
grep -E " E | F " logcat.log > errors_fatals.log

# ERROR + WARNING
grep -E " E | W " logcat.log > errors_warnings.log

# AndroidRuntime crashes
grep "AndroidRuntime" logcat.log > androidruntime.log

# FATAL EXCEPTION headers (with line numbers)
grep -n "FATAL EXCEPTION" logcat.log > fatal_exception.log

# Native crashes (signals)
grep -n "Fatal signal" logcat.log > native_crash.log

# General exceptions
grep -n "Exception"     logcat.log > exception.log
grep -n "java.lang."    logcat.log > java_lang.log

# Combined "serious problem" filter
egrep -n "FATAL EXCEPTION|AndroidRuntime|ANR in|Fatal signal|StrictMode|Exception" logcat.log > serious_problems.log

# Native crash with backtrace context
grep -B 2 -A 30 "signal 11\|SIGSEGV" live_boot_debug.log > native_crash_detail.log

# Most recent crash only
tac live_boot_debug.log | grep -m 1 -B 50 "CRASH\|FATAL" | tac > last_crash.log
```

---

## 6. ANR, StrictMode & Hangs

```bash
grep -n "ANR in" logcat.log > anr.log
grep -A 20 "ANR in" live_boot_debug.log > anr_detailed.log
grep -B 5  -A 20 "ANR in" live_boot_debug.log > anr_full_context.log
grep -n "StrictMode" logcat.log > strictmode.log
grep -E "BLOCKED|WAITING|deadlock" live_boot_debug.log > thread_issues.log
```

---

## 7. SELinux & Permission Errors

```bash
grep "avc: denied" logcat.log > avc_denied.log
grep "avc:"        logcat.log > avc_all.log
grep "avc: denied" logcat.log | grep -E "pid=|scontext=|tcontext=|tclass=" > avc_denied_compact.log

grep -i "permission denied"           logcat.log > permission_denied.log
grep -i "java.lang.SecurityException" logcat.log > java_securityexception.log
grep -i "requires android.permission" logcat.log > requires_android_permission.log
grep -i "Operation not permitted"     logcat.log > operation_not_permitted.log
grep -i "EACCES"                      logcat.log > eacces.log

# Combined security filter
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" logcat.log > security_combined.log

# Live capture of AVC denials
adb logcat -b all | grep "avc: denied"
```

> 👉 For deeper AVC analysis and automatic `.te` patch generation, see `02-selinux-avc-debugging.md`.

---

## 8. Performance & Memory

```bash
grep -E "MemoryPressure|LowMemory|OOM|OutOfMemory" live_boot_debug.log > memory_debug.log
grep "GC" live_boot_debug.log > gc_logs.log
grep -E "jank|dropped|frame.*ms" live_boot_debug.log > rendering_issues.log
grep -E "ANR|jank|frame|SLOW" live_boot_debug.log > performance_issues.log
```

---

## 9. Network & Connectivity

```bash
grep -E "ConnectivityService|NetworkInfo|NetworkStats|WiFi" live_boot_debug.log > network_debug.log
grep -E "getaddrinfo|dns|resolv" live_boot_debug.log > dns_logs.log
grep -E "socket|Connection refused|broken pipe" live_boot_debug.log > socket_errors.log
grep -E "SSL|TLS|Certificate|handshake" live_boot_debug.log > ssl_debug.log
```

---

## 10. Boot & Init

```bash
# Clear, reboot, wait, capture
adb logcat -c && adb reboot
sleep 60 && adb logcat > boot_debug.log

# Kernel / init boot messages
grep -E "init:|kernel:|boot:|init.rc" live_boot_debug.log > kernel_boot.log

# Early boot AVC denials
grep "avc:" live_boot_debug.log | head -50 > early_boot_sepolicy.log

# Boot timing markers
grep -E "init:|boot:|time=" boot_debug.log > boot_timing.log

# Live boot progress
adb logcat | grep -E "init:|boot:|Loading|Started" | tee boot_progress.log
```

---

## 11. Real-Time Monitoring

```bash
# Live errors
adb logcat | grep "error\|Error\|ERROR"

# Colorized
adb logcat | grep --color=always "error\|warning\|fatal"

# App live + save
adb logcat | grep "com.myapp" | tee app_realtime.log

# Multiple tags
adb logcat | grep -E "Tag1|Tag2|Tag3"

# Timestamped critical errors
adb logcat | grep -E "Exception|FATAL|ANR" | while read line; do echo "$(date): $line"; done | tee critical_errors.log

# Beep on error
adb logcat | grep --line-buffered " E " && echo -e '\a'
```

---

## 12. Output Formats

```bash
adb logcat -v brief   > logcat_brief.log
adb logcat -v process > logcat_process.log
adb logcat -v long    > logcat_long.log
adb logcat -v raw     > logcat_raw.log
adb logcat -v json    > logcat_json.log      # API 30+
adb logcat -v threadtime > logcat_threadtime.log
```

---

## 13. Statistics & Analysis

```bash
# Error frequency by tag (last field)
grep " E " live_boot_debug.log | awk '{print $NF}' | sort | uniq -c | sort -rn > error_by_tag.log

# Most frequent messages
awk '{$1=$2=$3=$4=$5=""; print $0}' live_boot_debug.log | sort | uniq -c | sort -rn | head -20 > frequent_logs.log

# Spammy debug sources
grep " D " live_boot_debug.log | cut -d':' -f1 | sort | uniq -c | sort -rn | head -20 > spam_sources.log

# Priority distribution
grep -o " [A-Z] " live_boot_debug.log | sort | uniq -c > priority_distribution.log

# One log file per priority
for priority in V D I W E F; do grep " $priority " live_boot_debug.log > "logs_${priority}.log"; done

# Crashes per process
grep -E "Process|Crash|died|signal" live_boot_debug.log > process_crashes.log

# Filesystem errors
grep -E "ENOENT|EACCES|I/O error|filesystem" live_boot_debug.log > fs_errors.log

# System property changes
grep "setprop\|ro\." live_boot_debug.log > property_changes.log
```

---

## 14. File Operations

```bash
gzip live_boot_debug.log          # compress
gunzip live_boot_debug.log.gz     # decompress
du -h live_boot_debug.log         # size
wc -l live_boot_debug.log         # line count
tail -n 100 live_boot_debug.log   # last 100 lines
head -n 100 live_boot_debug.log   # first 100 lines
```

---

## 15. Background Capture

```bash
adb logcat > debug.log &                       # background capture
pkill -f "adb logcat"                          # stop background
ps aux | grep adb                              # verify

# Multi-buffer background
adb logcat -b main   > main.log   &
adb logcat -b system > system.log &
adb logcat -b crash  > crash.log  &
```

---

## 16. Quick Recipes

### App crashes
```bash
adb logcat -b crash > crash_logs.log
grep -A 20 "CRASH\|Exception" crash_logs.log > crash_details.log
```

### Slow boot
```bash
adb logcat -c && adb reboot && sleep 60 && adb logcat > boot_debug.log
grep -E "init:|boot:|time=" boot_debug.log > boot_timing.log
```

### Memory pressure
```bash
adb logcat | grep -E "GC|OutOfMemory|MemoryPressure" | tee memory_issues.log
```

### Network broken
```bash
grep -E "ConnectivityService|WiFi|Network" live_boot_debug.log > network_issues.log
```

### Device freezing
```bash
grep -E "ANR|jank|frame|SLOW" live_boot_debug.log > performance_issues.log
```

### SELinux blocking functionality
```bash
grep "avc:" live_boot_debug.log > sepolicy.log
```

### Full diagnostic snapshot
```bash
adb logcat -c && \
adb logcat -v threadtime > full_diagnostic_$(date +%s).log &
adb logcat -b crash  >> crash_$(date +%s).log &
adb logcat -b system >> system_$(date +%s).log &
wait
echo "Capture complete"
```

### Extract all issues from an existing log
```bash
INPUT="live_boot_debug.log" && \
grep " E " "$INPUT" > errors.log && \
grep "avc:" "$INPUT" > sepolicy.log && \
grep -E "ANR|crash|FATAL" "$INPUT" > crashes.log && \
grep -E "Exception" "$INPUT" > exceptions.log && \
echo "Analysis complete: errors.log, sepolicy.log, crashes.log, exceptions.log"
```

### Monitor device with interactive stop
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

## 17. Notes

- Replace `live_boot_debug.log` / `logcat.log` with your actual file name.
- Replace `com.package.name` with your actual package.
- `>` overwrites, `>>` appends, `tee` saves + displays.
- Always `adb logcat -c` before capturing a specific event.
- For automated splitting, see `06-log-analysis-scripts.md`.
- For AVC policy fixes, see `02-selinux-avc-debugging.md`.

---

## 18. Battery Guru Permission

```bash
adb shell pm grant com.paget96.batteryguru android.permission.DUMP
```
```bash
adb shell pm grant com.paget96.batteryguru android.permission.BATTERY_STATS
```
```bash
adb shell pm grant com.paget96.batteryguru android.permission.WRITE_SECURE_SETTINGS
```
