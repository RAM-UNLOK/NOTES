```
display_engine_mode_entries
```

```
zipalign -c -P 16 -v 4 existing.apk
```

```
chmod +x fix_gcam.sh
```

```
./fix_gcam.sh
```

Since your APK does have compressed JNI libs, has_preprocessed_issues returns True, the if not condition is false, it skips the sys.exit, and the stamp file gets touched — build passes.
```
    presigned: true,
```
```
    preprocessed: true,
```
```
    skip_preprocessed_apk_checks: true,
```