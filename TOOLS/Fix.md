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

Patches 

✅ Fix 2 — Per-App dex2oat Compiler Filter
In your ROM's frameworks/base or via build.prop, force Instagram to use speed filter (skips re-verification):

# In device build.prop or BoardConfig
PRODUCT_PROPERTY_OVERRIDES += \
    pm.dexopt.install=speed \
    dalvik.vm.dex2oat-filter=speed

✅ Fix 3 — Add Verifier Exemption List
AOSP supports a verifier exemption list. In frameworks/base/core/res/res/xml/ or ART config:

xml<!-- art/tools/ahat/etc or system/etc -->
<hiddenapi-exemptions>
    <pattern>com/instagram/</pattern>
</hiddenapi-exemptions>

✅ Fix 4 — dex2oat Flags in Device Tree
In your device tree's device.mk:

PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-Xms=64m \
    dalvik.vm.dex2oat-Xmx=512m \
    dalvik.vm.dex2oat-filter=speed \
    dalvik.vm.image-dex2oat-filter=speed