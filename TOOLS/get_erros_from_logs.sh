 
# AOSP / Logcat Useful Grep Commands

## 1. Basic errors and fatals

```bash
# All ERROR and FATAL lines
grep -E " E | F " logcat.log
```

## 2. Java/Kotlin crashes (AndroidRuntime)

```bash
# AndroidRuntime crash lines
grep "AndroidRuntime" logcat.log

# FATAL EXCEPTION headers
grep -n "FATAL EXCEPTION" logcat.log

# Show AndroidRuntime lines with line numbers
grep -n "AndroidRuntime" logcat.log
```

## 3. ANR, native crash, strict mode

```bash
# ANR events (App Not Responding)
grep -n "ANR in" logcat.log

# Native crashes (signals)
grep -n "Fatal signal" logcat.log

# StrictMode violations
grep -n "StrictMode" logcat.log

# General exceptions
grep -n "Exception" logcat.log
grep -n "java.lang." logcat.log
```

## 4. Combined “serious problem” filter

```bash
# All serious error patterns in one shot
egrep -n "FATAL EXCEPTION|AndroidRuntime|ANR in|Fatal signal|StrictMode|Exception" logcat.log
```

## 5. Filter by package or PID

```bash
# By package name
PKG="com.example.app"
grep -n "$PKG" logcat.log | egrep "E |F |F |FATAL EXCEPTION|ANR in|Fatal signal"

# By process ID
PID=1234
grep -n " $PID " logcat.log | egrep "E |F |FATAL EXCEPTION|ANR in|Fatal signal"
```

## 6. SELinux AVC denials

```bash
# All SELinux AVC denials (full line)
grep "avc: denied" logcat.log

# All lines containing 'avc:' (even if not 'denied')
grep "avc:" logcat.log

# AVC denials with useful fields
grep "avc: denied" logcat.log | grep -E "pid=|scontext=|tcontext=|tclass="

# Live capture from all buffers (device connected)
adb logcat -b all | grep "avc: denied"
```

## 7. Permission-related errors

```bash
# Generic permission denied errors
grep -i "permission denied" logcat.log

# Java/Kotlin security exceptions
grep -i "java.lang.SecurityException" logcat.log

# Missing Android permissions (manifest / runtime)
grep -i "requires android.permission" logcat.log
```

## 8. Other access / security errors

```bash
# SecurityException (general)
grep -i "SecurityException" logcat.log

# Operation not permitted
grep -i "Operation not permitted" logcat.log

# POSIX access errors
grep -i "EACCES" logcat.log
```

## 9. Big combined security / SELinux filter

```bash
# One big filter for SELinux + permission issues
egrep -i "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" logcat.log

# Same, with line numbers
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" logcat.log
```

## 10. Focus on your HAL / service / process

```bash
# Replace with your service / HAL name
grep "my_hal_or_service_name" logcat.log | egrep -i "avc: denied|permission denied|SecurityException"

# If you know the PID
PID=1234
grep " pid=${PID} " logcat.log | egrep -i "avc: denied|permission denied|SecurityException"
```

## 11. Bash script to auto-split key errors

Save as `split_logcat_errors.sh`, `chmod +x split_logcat_errors.sh`,
and run as: `./split_logcat_errors.sh logcat.log`

```bash
#!/usr/bin/env bash

LOGFILE="${1:-logcat.log}"

out() {
  echo "[*] $1 -> $2"
}

# 1. Basic errors / fatals
grep -E " E | F " "$LOGFILE" > errors_fatals.txt
out "Errors and fatals" "errors_fatals.txt"

# 2. AndroidRuntime / FATAL EXCEPTION
grep "AndroidRuntime" "$LOGFILE" > androidruntime.txt
grep -n "FATAL EXCEPTION" "$LOGFILE" > fatal_exception.txt
out "AndroidRuntime" "androidruntime.txt"
out "FATAL EXCEPTION" "fatal_exception.txt"

# 3. ANR / native crash / StrictMode / exceptions
grep -n "ANR in" "$LOGFILE" > anr.txt
grep -n "Fatal signal" "$LOGFILE" > native_crash_fatal_signal.txt
grep -n "StrictMode" "$LOGFILE" > strictmode.txt
grep -n "Exception" "$LOGFILE" > exception.txt
grep -n "java.lang." "$LOGFILE" > java_lang.txt
out "ANR" "anr.txt"
out "Native crashes" "native_crash_fatal_signal.txt"
out "StrictMode" "strictmode.txt"
out "Exceptions" "exception.txt"
out "java.lang.*" "java_lang.txt"

# 4. SELinux AVC
grep "avc:" "$LOGFILE" > avc_all.txt
grep "avc: denied" "$LOGFILE" > avc_denied.txt
grep "avc: denied" "$LOGFILE" | grep -E "pid=|scontext=|tcontext=|tclass=" > avc_denied_compact.txt
out "All avc:" "avc_all.txt"
out "avc: denied" "avc_denied.txt"
out "avc: denied (compact)" "avc_denied_compact.txt"

# 5. Permission / security / access errors
grep -i "permission denied" "$LOGFILE" > permission_denied.txt
grep -i "java.lang.SecurityException" "$LOGFILE" > java_securityexception.txt
grep -i "requires android.permission" "$LOGFILE" > requires_android_permission.txt
grep -i "SecurityException" "$LOGFILE" > securityexception_any.txt
grep -i "Operation not permitted" "$LOGFILE" > operation_not_permitted.txt
grep -i "EACCES" "$LOGFILE" > eacces.txt
out "permission denied" "permission_denied.txt"
out "java.lang.SecurityException" "java_securityexception.txt"
out "requires android.permission" "requires_android_permission.txt"
out "SecurityException (any)" "securityexception_any.txt"
out "Operation not permitted" "operation_not_permitted.txt"
out "EACCES" "eacces.txt"

# 6. Combined security / SELinux
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" "$LOGFILE" > security_selinux_combined.txt
out "Combined security/SELinux" "security_selinux_combined.txt"

echo "[*] Done."
```
