# ADB Logcat Debugging Commands - Quick Copy Format

## 1. BASIC LOGCAT CAPTURE COMMANDS

### Capture all logs to a file
```bash
adb logcat > live_boot_debug.log
```

### Capture logs in real-time while saving
```bash
adb logcat | tee live_boot_debug.log
```

### Capture logs with timestamps
```bash
adb logcat -v time > logcat_with_time.log
```

### Capture logs with threadtime format
```bash
adb logcat -v threadtime > logcat_threadtime.log
```

### Clear previous logs before capture
```bash
adb logcat -c && adb logcat > fresh_debug.log
```

---

## 2. SELINUX & SECURITY POLICY DENIALS

### Extract SELinux policy violations (AVC)
```bash
grep "avc:" live_boot_debug.log > sepolicy_denials.log
```

### Extract all SELinux denials with context
```bash
grep -A 2 "avc:" live_boot_debug.log > sepolicy_with_context.log
```

### Get SELinux denials for specific process
```bash
grep "avc:.*init" live_boot_debug.log > init_sepolicy.log
```

### Monitor SELinux denials in real-time
```bash
adb logcat | grep "avc:" | tee sepolicy_live.log
```

---

## 3. ERROR & EXCEPTION FILTERING

### Extract all ERROR level logs
```bash
grep " E " live_boot_debug.log > errors_only.log
```

### Extract ERROR and WARNING levels
```bash
grep -E " E | W " live_boot_debug.log > errors_warnings.log
```

### Extract FATAL and CRASH logs
```bash
grep -E "FATAL|crash|CRASH|exception" live_boot_debug.log > crashes.log
```

### Get Android Framework errors
```bash
grep -E "AndroidRuntime|FATAL EXCEPTION" live_boot_debug.log > framework_errors.log
```

### Extract Java exceptions with stack traces
```bash
grep -A 15 "Exception\|Error:" live_boot_debug.log > exceptions_stacktrace.log
```

---

## 4. PROCESS & APPLICATION SPECIFIC DEBUGGING

### Get logs for specific package name
```bash
adb logcat | grep "com.package.name" | tee app_debug.log
```

### Get logs by package PID (get PID first)
```bash
adb shell pidof com.package.name
```

### Filter logs by specific PID
```bash
adb logcat --pid=<PID> > app_specific.log
```

### Filter by multiple package names
```bash
grep -E "com.package1|com.package2" live_boot_debug.log > multi_app_debug.log
```

### Get logs for system services
```bash
grep -E "SystemServiceManager|ServiceManager" live_boot_debug.log > system_services.log
```

---

## 5. LOG PRIORITY FILTERING

### Extract only ERROR level logs
```bash
adb logcat "*:E" > errors.log
```

### Extract WARNING and above (W, E, F)
```bash
adb logcat "*:W" > warnings_and_above.log
```

### Extract DEBUG level logs
```bash
adb logcat "*:D" > debug_logs.log
```

### Extract INFO and above
```bash
adb logcat "*:I" > info_and_above.log
```

### Mixed: Get ERROR from one tag, DEBUG from another
```bash
adb logcat "SystemServer:E" "ActivityManager:D" > mixed_priority.log
```

---

## 6. BOOT & SYSTEM INITIALIZATION

### Clear logs and reboot
```bash
adb logcat -c && adb reboot
```

### Wait for device to boot (30 seconds) and capture
```bash
sleep 30 && adb logcat > boot_sequence.log
```

### Filter kernel initialization messages
```bash
grep -E "init:|kernel:|boot:|init.rc" live_boot_debug.log > kernel_boot.log
```

### Get SELinux boot denials (first 50)
```bash
grep "avc:" live_boot_debug.log | head -50 > early_boot_sepolicy.log
```

### Monitor boot progress in real-time
```bash
adb logcat | grep -E "init:|boot:|Loading|Started" | tee boot_progress.log
```

---

## 7. PERFORMANCE & MEMORY DEBUGGING

### Capture memory-related logs
```bash
grep -E "MemoryPressure|LowMemory|OOM|OutOfMemory" live_boot_debug.log > memory_debug.log
```

### Get garbage collection logs
```bash
grep "GC" live_boot_debug.log > gc_logs.log
```

### Extract ANR (Application Not Responding) logs
```bash
grep -A 20 "ANR in" live_boot_debug.log > anr_logs.log
```

### Monitor native crashes
```bash
grep -E "signal 11|SIGSEGV|abort|backtrace" live_boot_debug.log > native_crashes.log
```

### Get frame drops and rendering issues
```bash
grep -E "jank|dropped|frame.*ms" live_boot_debug.log > rendering_issues.log
```

---

## 8. THREAD & TAG FILTERING

### Filter by ActivityManager tag
```bash
grep "ActivityManager" live_boot_debug.log > activity_manager.log
```

### Get logs from multiple system tags
```bash
grep -E "ActivityManager|WindowManager|PackageManager" live_boot_debug.log > system_managers.log
```

### Extract specific thread logs
```bash
grep "tid=" live_boot_debug.log | head -20 > thread_logs.log
```

### Monitor SurfaceFlinger in real-time
```bash
adb logcat | grep "SurfaceFlinger" | tee surfaceflinger.log
```

---

## 9. NETWORK & CONNECTIVITY DEBUGGING

### Get network-related logs
```bash
grep -E "ConnectivityService|NetworkInfo|NetworkStats|WiFi" live_boot_debug.log > network_debug.log
```

### Extract DNS resolution logs
```bash
grep -E "getaddrinfo|dns|resolv" live_boot_debug.log > dns_logs.log
```

### Monitor socket/connection errors
```bash
grep -E "socket|Connection refused|broken pipe" live_boot_debug.log > socket_errors.log
```

### Get SSL/TLS issues
```bash
grep -E "SSL|TLS|Certificate|handshake" live_boot_debug.log > ssl_debug.log
```

---

## 10. DETAILED OUTPUT FORMATS

### Capture with brief format
```bash
adb logcat -v brief > logcat_brief.log
```

### Capture with process information
```bash
adb logcat -v process > logcat_process.log
```

### Most detailed format (long)
```bash
adb logcat -v long > logcat_long.log
```

### JSON format (API 30+)
```bash
adb logcat -v json > logcat_json.log
```

### Raw format (minimal)
```bash
adb logcat -v raw > logcat_raw.log
```

---

## 11. ADVANCED FILTERING & ANALYSIS

### Find all processes that crashed
```bash
grep -E "Process|Crash|died|signal" live_boot_debug.log > process_crashes.log
```

### Extract permission-related issues
```bash
grep -E "Permission denied|permission|PERMISSION_" live_boot_debug.log > permission_issues.log
```

### Get database issues
```bash
grep -E "database|sqlite|cursor|transaction" live_boot_debug.log > database_debug.log
```

### Extract file system errors
```bash
grep -E "ENOENT|EACCES|I/O error|filesystem" live_boot_debug.log > fs_errors.log
```

### Monitor system property changes
```bash
grep "setprop\|ro\." live_boot_debug.log > property_changes.log
```

---

## 12. REAL-TIME MONITORING

### Monitor errors in real-time
```bash
adb logcat | grep "error\|Error\|ERROR"
```

### Real-time monitoring with color highlighting
```bash
adb logcat | grep --color=always "error\|warning\|fatal"
```

### Monitor and save specific app in real-time
```bash
adb logcat | grep "com.myapp" | tee app_realtime.log
```

### Monitor multiple tags
```bash
adb logcat | grep -E "Tag1|Tag2|Tag3"
```

### Watch for critical errors and timestamp them
```bash
adb logcat | grep -E "Exception|FATAL|ANR" | while read line; do echo "$(date): $line"; done | tee critical_errors.log
```

---

## 13. COMBINED & COMPLEX FILTERING

### Get errors excluding specific patterns
```bash
grep " E " live_boot_debug.log | grep -v "ignoring\|Debug" > errors_filtered.log
```

### Find ANRs with full details
```bash
grep -B 5 -A 20 "ANR in" live_boot_debug.log > anr_detailed.log
```

### Extract native crash with backtrace
```bash
grep -B 2 -A 30 "signal 11\|SIGSEGV" live_boot_debug.log > native_crash_detail.log
```

### Get all unique error messages with frequency
```bash
grep " E " live_boot_debug.log | sort | uniq -c | sort -rn > error_frequency.log
```

### Find deadlocks or blocked threads
```bash
grep -E "BLOCKED|WAITING|deadlock" live_boot_debug.log > thread_issues.log
```

---

## 14. LOGCAT BUFFER MANAGEMENT

### View available buffers and size
```bash
adb logcat -g
```

### Increase logcat buffer size to 16MB
```bash
adb logcat -G 16M
```

### Capture from main buffer only
```bash
adb logcat -b main > main_buffer.log
```

### Capture from system buffer only
```bash
adb logcat -b system > system_buffer.log
```

### Capture from events buffer only
```bash
adb logcat -b events > events_buffer.log
```

### Capture from crash buffer only
```bash
adb logcat -b crash > crash_buffer.log
```

### Capture from all buffers simultaneously
```bash
adb logcat -b main -b system -b crash > all_buffers.log
```

### Get kernel messages
```bash
adb shell cat /proc/kmsg > kernel_messages.log
```

---

## 15. STATISTICS & ANALYSIS

### Count error occurrences by tag
```bash
grep " E " live_boot_debug.log | awk '{print $NF}' | sort | uniq -c | sort -rn > error_by_tag.log
```

### Get most frequent log messages
```bash
awk '{$1=$2=$3=$4=$5=""; print $0}' live_boot_debug.log | sort | uniq -c | sort -rn | head -20 > frequent_logs.log
```

### Find spammy logs (DEBUG level)
```bash
grep " D " live_boot_debug.log | cut -d':' -f1 | sort | uniq -c | sort -rn | head -20 > spam_sources.log
```

### Count logs by priority level
```bash
grep -o " [A-Z] " live_boot_debug.log | sort | uniq -c > priority_distribution.log
```

---

## 16. USEFUL ONE-LINERS

### Quick capture and immediate filter for errors
```bash
adb logcat 2>&1 | tee capture.log | grep -i error
```

### Capture with automatic timestamp naming
```bash
adb logcat > "logcat_$(date +%Y%m%d_%H%M%S).log"
```

### Find the most recent crash
```bash
tac live_boot_debug.log | grep -m 1 -B 50 "CRASH\|FATAL" | tac > last_crash.log
```

### Create separate logs for each priority level
```bash
for priority in V D I W E F; do grep " $priority " live_boot_debug.log > "logs_${priority}.log"; done
```

### Monitor and beep on errors
```bash
adb logcat | grep --line-buffered " E " && echo -e '\a'
```

### Get system boot time estimation
```bash
grep "boot\|Boot" live_boot_debug.log | head -5 > boot_timing.log
```

---

## 17. BACKGROUND CAPTURE

### Start capture in background
```bash
adb logcat > debug.log &
```

### Stop background logcat process
```bash
pkill -f "adb logcat"
```

### Capture multiple buffers in background
```bash
adb logcat -b main > main.log & adb logcat -b system > system.log & adb logcat -b crash > crash.log &
```

### Check active background processes
```bash
ps aux | grep adb
```

---

## 18. FILE OPERATIONS

### Compress old log files
```bash
gzip *.log
```

### Compress specific log file
```bash
gzip live_boot_debug.log
```

### Decompress log file
```bash
gunzip live_boot_debug.log.gz
```

### Get log file size
```bash
du -h live_boot_debug.log
```

### Count total lines in log
```bash
wc -l live_boot_debug.log
```

### View last 100 lines of log
```bash
tail -n 100 live_boot_debug.log
```

### View first 100 lines of log
```bash
head -n 100 live_boot_debug.log
```

---

## 19. PERMISSION & SECURITY DEBUGGING

### Extract all permission denied errors
```bash
grep -i "permission denied" live_boot_debug.log > permission_denied.log
```

### Get file permission issues
```bash
grep -E "EACCES|Permission" live_boot_debug.log > file_permissions.log
```

### Extract SELinux context information
```bash
grep "scontext=\|tcontext=" live_boot_debug.log > selinux_context.log
```

### Find all denied operations
```bash
grep "denied" live_boot_debug.log > denied_operations.log
```

---

## 20. QUICK REFERENCE - COMMON SCENARIOS

### My app keeps crashing - Get crash logs
```bash
adb logcat -b crash > crash_logs.log
```

### Show exceptions from crash buffer
```bash
grep -A 20 "CRASH\|Exception" crash_logs.log > crash_details.log
```

### Phone boots slowly - Capture boot sequence
```bash
adb logcat -c && adb reboot && sleep 60 && adb logcat > boot_debug.log
```

### Show boot timing information
```bash
grep -E "init:|boot:|time=" boot_debug.log > boot_timing.log
```

### SELinux is blocking functionality
```bash
grep "avc:" live_boot_debug.log > sepolicy.log
```

### App uses too much memory
```bash
adb logcat | grep -E "GC|OutOfMemory|MemoryPressure" | tee memory_issues.log
```

### Network not working
```bash
grep -E "ConnectivityService|WiFi|Network" live_boot_debug.log > network_issues.log
```

### App is slow/freezing
```bash
grep -E "ANR|jank|frame|SLOW" live_boot_debug.log > performance_issues.log
```

---

## 21. COMBINED SCRIPTS - DO EVERYTHING AT ONCE

### Full diagnostic capture (all buffers, all formats)
```bash
adb logcat -c && \
adb logcat -v threadtime > full_diagnostic_$(date +%s).log &
adb logcat -b crash >> crash_$(date +%s).log &
adb logcat -b system >> system_$(date +%s).log &
wait
echo "Capture complete"
```

### Extract all issues from existing log
```bash
INPUT="live_boot_debug.log" && \
grep " E " "$INPUT" > errors.log && \
grep "avc:" "$INPUT" > sepolicy.log && \
grep -E "ANR|crash|FATAL" "$INPUT" > crashes.log && \
grep -E "Exception" "$INPUT" > exceptions.log && \
echo "Analysis complete: errors.log, sepolicy.log, crashes.log, exceptions.log"
```

### Monitor device and capture everything
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

## NOTES:
- Replace `live_boot_debug.log` with your actual log file name
- Replace `com.package.name` with your actual package name
- Use `|` (pipe) for real-time processing
- Use `>` for saving to file (overwrites)
- Use `>>` for appending to file
- Use `tee` to both save and display
- Always use `adb logcat -c` to clear old logs before capture
