# SELinux AVC Denial Debugging & Fix Generation

Extract, analyze, and generate modern `.te` policy patches from Android SELinux AVC denials.

---

## Table of Contents

1. [Extracting AVC Denials](#1-extracting-avc-denials)
2. [Analysing Denials](#2-analysing-denials)
3. [Modern Android Macro Reference](#3-modern-android-macro-reference-android-12)
4. [Manual Rule Translation Examples](#4-manual-rule-translation-examples)
5. [Automated Fix Generator (avc_fix_generator.py)](#5-automated-fix-generator-avc_fix_generatorpy)
6. [Live Device Workflow](#6-live-device-workflow)
7. [Where to Apply the Patches](#7-where-to-apply-the-patches)
8. [Notes](#8-notes)

---

## 1. Extracting AVC Denials

### Basic extraction
```bash
# All denials
grep "avc: denied" logcat.log > avc_denied.log

# Every avc: line (denied or not)
grep "avc:" logcat.log > avc_all.log

# With full context fields
grep "avc: denied" logcat.log | grep -E "pid=|scontext=|tcontext=|tclass=" > avc_denied_compact.log

# Just the assertion body (fields 3+), sorted unique
grep "avc:" full_logcat1.log | cut -d' ' -f3- | sort -u > sorted_avc_denials.txt

# Live
adb logcat -b all | grep "avc: denied"
```

### AVC denial anatomy
```
avc: denied { open read } for pid=1234 comm="mtk_hal_audio"
     name="foo" dev="dm-0" ino=9876
     scontext=u:r:mtk_hal_audio:s0     ← who is blocked
     tcontext=u:object_r:foo_prop:s0   ← what is blocked
     tclass=file                        ← object class
     permissive=0
```

| Field | Meaning |
|---|---|
| `{ ... }` | Required permissions |
| `scontext` | Source domain (`u:r:<domain>:s0`) |
| `tcontext` | Target type (`u:object_r:<type>:s0`) |
| `tclass` | Object class (`file`, `dir`, `chr_file`, `service_manager`, …) |
| `name=` | Specific filename or service name (optional) |
| `permissive=0` | Enforcing (a real denial) |
| `permissive=1` | Permissive mode (logged, not blocked) |

---

## 2. Analysing Denials

### Filter by domain / process
```bash
grep "avc:.*mtk_hal_audio" logcat.log
grep "avc:.*init"          logcat.log
grep "avc:.*vendor_init"   logcat.log

# Filter by service/domain name
grep "avc:" logcat.log | grep "my_hal_or_service_name"

# Filter by PID
PID=1234
grep " pid=${PID} " logcat.log | grep "avc:"
```

### Combined SELinux + permission errors
```bash
egrep -ni "avc: denied|permission denied|SecurityException|EACCES|Operation not permitted" logcat.log > security_selinux_combined.log
```

### Group unique denials (scontext + tcontext + tclass + name)
```bash
grep "avc: denied" logcat.log \
  | sed -E 's/.*scontext=([^ ]+) tcontext=([^ ]+) tclass=([^ ]+).*/\1 -> \2:\3/' \
  | sort -u > unique_avc_groups.txt
```

### Count denials per target
```bash
grep "avc: denied" logcat.log \
  | grep -oE "tcontext=[^ ]+ tclass=[^ ]+" \
  | sort | uniq -c | sort -rn > avc_targets_ranked.txt
```

---

## 3. Modern Android Macro Reference (Android 12+)

### Properties
```
get_prop(domain, prop_type)
set_prop(domain, prop_type)
```

`set_prop()` expands to cover:
- `property_service { set }`
- `property_socket:sock_file { write }`
- `init:unix_stream_socket { connectto }`

`get_prop()` expands to cover:
- `<prop_type>:file r_file_perms`
- `property_service { read }`

### Files
```
r_file_perms   = { getattr open read }
w_file_perms   = { getattr open append write }
rw_file_perms  = { getattr open read write ioctl lock append }
rx_file_perms  = { getattr open read execute }
```

### Directories
```
r_dir_perms    = { open getattr read search }
rw_dir_perms   = { open getattr read search write add_name remove_name }
```

### Char / block devices (convention)
```
read:  { open read ioctl getattr }
rw:    { open read write ioctl getattr }
```

### Services
```
add_service(domain, svc_type)     # AIDL (Android 11+)
get_service(domain, svc_type)
add_hwservice(domain, svc_type)   # HIDL
get_hwservice(domain, svc_type)
```

### Binder & Sockets
```
binder_use(domain)
binder_call(client, server)
unix_socket_connect(domain, socket, server)
```

---

## 4. Manual Rule Translation Examples

| AVC denial | Modern rule |
|---|---|
| `property_service { set }` | `set_prop(vendor_init, foo_prop)` |
| `<foo>_prop:file { read }` | `get_prop(domain, foo_prop)` |
| `service_manager { add }` | `add_service(domain, svc_type)` + declare in `service_contexts` |
| `service_manager { find }` | `get_service(domain, svc_type)` |
| `hwservice_manager { add }` | `add_hwservice(domain, svc_type)` + declare in `hwservice_contexts` |
| `hwservice_manager { find }` | `get_hwservice(domain, svc_type)` |
| `property_socket:sock_file { write }` | use `set_prop()` (or `unix_socket_connect(domain, property, init)`) |
| `file { getattr open read }` | `allow domain type:file r_file_perms;` |
| `dir  { open getattr read search }` | `allow domain type:dir r_dir_perms;` |
| `chr_file { open read write ioctl getattr }` | `allow domain type:chr_file { open read write ioctl getattr };` |

### Anti-patterns to avoid
- ❌ `allow domain proc:file ...` → label a specific `proc_*` type instead
- ❌ `allow domain sysfs:file ...` → label a specific `sysfs_*` type instead
- ❌ `unix_socket_connect(domain, property, init)` when you actually need property **writes** → use `set_prop()`
- ❌ Widening to `permissive` domains in shipping policy

### Context file declarations

**`service_contexts`** (for `add_service` / `get_service`):
```
<service/name>       u:object_r:<svc_type>:s0
```

**`hwservice_contexts`** (for `add_hwservice` / `get_hwservice`):
```
<android.hardware.foo@1.0::IFoo>   u:object_r:<svc_type>:s0
```

**`property_contexts`** (for `set_prop` / `get_prop`):
```
<prop.name.prefix>   u:object_r:<prop_type>:s0
```

---

## 5. Automated Fix Generator (`avc_fix_generator.py`)

### Usage
```bash
python3 avc_fix_generator.py full_logcat.log
```

### Outputs
- `avc_denial_report.txt` — human-readable report
- `te_patches/<domain>.te` — ready-to-paste policy snippets
- `summary_table.txt` — one-row-per-denial quick reference

### Full script

```python
#!/usr/bin/env python3
"""
AVC Denial Fix Generator — Modern Android SELinux Style
========================================================
Parses AVC denials from logcat and emits modern macro-based .te rules.

Usage:
    python3 avc_fix_generator.py <logcat_file>
"""

import re, sys, os
from collections import defaultdict
from dataclasses import dataclass


@dataclass(frozen=True)
class Denial:
    scontext: str
    tcontext: str
    tclass:   str
    actions:  frozenset
    name:     str


AVC_RE = re.compile(
    r"avc:\s+denied\s+\{([^}]+)\}\s+for\s+"
    r"(?:.*?name=\"([^\"]+)\".*?)?"
    r"scontext=(\S+)\s+tcontext=(\S+)\s+tclass=(\S+)"
)


def _domain(ctx):
    p = ctx.split(":")
    return p[2] if len(p) >= 3 else ctx


def parse(path):
    raw = defaultdict(set)
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            m = AVC_RE.search(line)
            if not m:
                continue
            acts_raw, name, sctx, tctx, tclass = m.groups()
            acts = frozenset(a.strip() for a in acts_raw.split() if a.strip())
            key  = (_domain(sctx), _domain(tctx), tclass, name or "")
            raw[key] |= acts
    return [Denial(k[0], k[1], k[2], frozenset(v), k[3]) for k, v in raw.items()]


# ── suggested .te file ────────────────────────────────────────
TE_MAP = {
    "vendor_init":                   "vendor/sepolicy/vendor_init.te",
    "init":                          "system/sepolicy/private/init.te",
    "mtk_hal_audio":                 "vendor/sepolicy/mtk_hal_audio.te",
    "hal_graphics_composer_default": "vendor/sepolicy/hal_graphics_composer_default.te",
}


def te_file(src):
    return TE_MAP.get(src, f"vendor/sepolicy/{src}.te")


# ── modern perm macro resolver ────────────────────────────────
def perm_macro(acts, tclass):
    a = acts
    if tclass in ("file", "chr_file", "blk_file"):
        if "read" in a and "write" in a:    return "rw_file_perms"
        if "read" in a and "execute" in a:  return "rx_file_perms"
        if "read" in a:                     return "r_file_perms"
        if "write" in a:                    return "w_file_perms"
        return "{ " + " ".join(sorted(a)) + " }"
    if tclass == "dir":
        if a & {"write", "add_name", "remove_name"}: return "rw_dir_perms"
        return "r_dir_perms"
    return "{ " + " ".join(sorted(a)) + " }"


# ── main rule builder ─────────────────────────────────────────
def build_rule(d):
    src, tgt, tclass, acts = d.scontext, d.tcontext, d.tclass, d.actions
    tf = te_file(src)

    # 1. property_service → set_prop macro
    if tclass == "property_service" and "set" in acts:
        return dict(
            rule=f"set_prop({src}, {tgt})",
            macro="set_prop",
            note=(f"Covers: property_service {{set}}, property_socket sock_file {{write}}, "
                  f"init unix_stream_socket {{connectto}}. "
                  f"Declare '{tgt}' in property_contexts if not already present."),
            te_file=tf,
        )

    # 2. prop:file read → get_prop macro
    if tclass == "file" and tgt.endswith("_prop"):
        return dict(
            rule=f"get_prop({src}, {tgt})",
            macro="get_prop",
            note=(f"Covers: {tgt}:file r_file_perms + property_service {{read}}. "
                  f"Declare '{tgt}' in property_contexts."),
            te_file=tf,
        )

    # 3. service_manager AIDL
    if tclass == "service_manager" and "add" in acts:
        svc_ctx = tgt
        return dict(
            rule=(f"add_service({src}, {svc_ctx})\n"
                  f"# Declare in service_contexts:\n"
                  f"# {d.name or '<service/name>'}  u:object_r:{svc_ctx}:s0"),
            macro="add_service",
            note=(f"AIDL service registration (Android 11+ servicemanager). "
                  f"Also call binder_use({src}) if not already present."),
            te_file=tf,
        )

    if tclass == "service_manager" and "find" in acts:
        return dict(
            rule=f"get_service({src}, {tgt})",
            macro="get_service",
            note="AIDL service lookup.",
            te_file=tf,
        )

    # 4. hwservice_manager HIDL
    if tclass == "hwservice_manager" and "add" in acts:
        return dict(
            rule=(f"add_hwservice({src}, {tgt})\n"
                  f"# Declare in hwservice_contexts."),
            macro="add_hwservice",
            note="HIDL service registration.",
            te_file=tf,
        )
    if tclass == "hwservice_manager" and "find" in acts:
        return dict(
            rule=f"get_hwservice({src}, {tgt})",
            macro="get_hwservice",
            note="HIDL service lookup.",
            te_file=tf,
        )

    # 5. property socket → prefer set_prop or unix_socket_connect
    if tclass == "sock_file" and tgt == "property_socket":
        return dict(
            rule=(f"# Preferred: use set_prop({src}, <prop_type>) — covers socket + property\n"
                  f"# If you only need raw socket access (no property write):\n"
                  f"unix_socket_connect({src}, property, init)"),
            macro="unix_socket_connect / set_prop",
            note=(f"set_prop() is preferred as it covers the full property-set flow. "
                  f"unix_socket_connect is for raw socket access only."),
            te_file=tf,
        )

    # 6. chr_file devices — always add open + ioctl + getattr
    if tclass == "chr_file":
        if "read" in acts and "write" in acts:
            perm = "{ open read write ioctl getattr }"
        elif "read" in acts:
            perm = "{ open read ioctl getattr }"
        elif "write" in acts:
            perm = "{ open write ioctl getattr }"
        else:
            perm = "{ " + " ".join(sorted(acts)) + " }"
        rule = f"allow {src} {tgt}:{tclass} {perm};"
        note = (f"open+ioctl+getattr included by convention for chr_file. "
                f"Verify '{tgt}' label in vendor_file_contexts / file_contexts.")
        return dict(rule=rule, macro=perm, note=note, te_file=tf)

    # 7. generic file — use macros
    if tclass in ("file", "dir"):
        perm = perm_macro(acts, tclass)

        if tclass == "file" and tgt in ("proc", "sysfs"):
            note = (f"AVOID generic '{tgt}' type. Add a specific genfscon/file_contexts label "
                    f"(e.g. proc_meminfo, sysfs_devices_system_cpu) and allow that type instead.")
        elif tclass == "file" and tgt.startswith("sysfs_"):
            note = (f"r_file_perms = {{getattr open read}}. "
                    f"Verify the genfscon entry covers the correct sysfs path for '{tgt}'.")
        elif tclass == "dir" and tgt.startswith("proc_"):
            note = (f"r_dir_perms = {{open getattr read search}}. "
                    f"'{tgt}' is the correct specific proc label — do not fall back to 'proc'.")
        elif tclass == "dir" and "_data_file" in tgt:
            note = (f"r_dir_perms grants directory traversal/search. "
                    f"You will likely also need r_file_perms on '{tgt}:file' for the files inside.")
        else:
            note = f"Standard {tclass} access."

        return dict(rule=f"allow {src} {tgt}:{tclass} {perm};",
                    macro=perm, note=note, te_file=tf)

    # 8. fallback
    perm = "{ " + " ".join(sorted(acts)) + " }"
    return dict(rule=f"allow {src} {tgt}:{tclass} {perm};",
                macro=perm, note=f"Standard {tclass} rule.", te_file=tf)


# ── output renderers ──────────────────────────────────────────

def render_report(denials):
    lines = [
        "=" * 72,
        "  AVC DENIAL FIX REPORT  —  Modern Android SELinux Macros",
        "=" * 72,
        f"  Unique denial groups : {len(denials)}",
        "",
    ]
    by_file = defaultdict(list)
    for d in denials:
        r = build_rule(d)
        by_file[r["te_file"]].append((d, r))

    for tf in sorted(by_file):
        lines += ["─" * 72, f"  FILE ▶  {tf}", "─" * 72]
        for d, r in by_file[tf]:
            tag = f"  [{d.name}]" if d.name else ""
            lines += [
                "",
                f"  Denial  : {d.scontext} → {d.tcontext}:{d.tclass}{tag}",
                f"  Actions : {' '.join(sorted(d.actions))}",
                f"  Macro   : {r['macro']}",
                "  Rule    :",
            ]
            for ln in r["rule"].splitlines():
                lines.append(f"      {ln}")
            lines.append(f"  Note    : {r['note']}")
        lines.append("")
    return "\n".join(lines)


def render_te_patches(denials):
    by_file = defaultdict(list)
    for d in denials:
        r = build_rule(d)
        by_file[r["te_file"]].append((d, r))

    result = {}
    for tf, items in sorted(by_file.items()):
        domain = os.path.splitext(os.path.basename(tf))[0]
        lines = [
            f"# ── {domain}.te  —  modern Android SELinux policy patch ──",
            f"# Target file : {tf}",
            f"# Style       : Android 12+ macros",
            "",
        ]
        for d, r in items:
            tag = f" [{d.name}]" if d.name else ""
            lines += [
                f"# Denial: {d.scontext} → {d.tcontext}:{d.tclass}{tag}",
                f"# Note  : {r['note']}",
                r["rule"],
                "",
            ]
        result[tf] = "\n".join(lines)
    return result


def render_table(denials):
    rows = [
        f"{'SOURCE DOMAIN':<42} {'TARGET:CLASS':<46} RULE",
        "-" * 120,
    ]
    for d in sorted(denials, key=lambda x: (x.scontext, x.tcontext)):
        r = build_rule(d)
        rows.append(
            f"{d.scontext:<42} {d.tcontext+':'+d.tclass:<46} "
            f"{r['rule'].splitlines()[0]}"
        )
    return "\n".join(rows)


# ── main ──────────────────────────────────────────────────────

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "full_logcat.log"
    if not os.path.exists(path):
        sys.exit(f"[ERROR] File not found: {path}")

    print(f"[*] Parsing {path} …")
    denials = parse(path)
    print(f"[*] {len(denials)} unique denial groups\n")

    with open("avc_denial_report.txt", "w") as f:
        f.write(render_report(denials))
    print("[+] avc_denial_report.txt")

    os.makedirs("te_patches", exist_ok=True)
    for tf, content in render_te_patches(denials).items():
        out = os.path.join("te_patches", os.path.basename(tf))
        with open(out, "w") as f:
            f.write(content)
        print(f"[+] te_patches/{os.path.basename(tf)}")

    with open("summary_table.txt", "w") as f:
        f.write(render_table(denials))
    print("[+] summary_table.txt\n")

    print(render_report(denials))


if __name__ == "__main__":
    main()
```

### Sample output shape

```
====================================================================
  AVC DENIAL FIX REPORT  —  Modern Android SELinux Macros
====================================================================
  Unique denial groups : 3

────────────────────────────────────────────────────────────────────
  FILE ▶  vendor/sepolicy/mtk_hal_audio.te
────────────────────────────────────────────────────────────────────

  Denial  : mtk_hal_audio → foo_prop:property_service  [foo.bar]
  Actions : set
  Macro   : set_prop
  Rule    :
      set_prop(mtk_hal_audio, foo_prop)
  Note    : Covers: property_service {set}, property_socket sock_file {write},
            init unix_stream_socket {connectto}. Declare 'foo_prop' in
            property_contexts if not already present.
```

---

## 6. Live Device Workflow

### Enable linker / policy debug (userdebug builds)
```bash
# Temporarily permissive (DEBUG ONLY — never ship)
adb root
adb shell setenforce 0

# Enable SELinux verbose tag
adb shell setprop persist.log.tag.SELinux D
```

### Capture denials while exercising the app
```bash
adb logcat -c
adb logcat -b all | grep "avc: denied" | tee avc_live.log
# (reproduce the issue on device)
# Ctrl+C
```

### Feed the capture into the generator
```bash
python3 avc_fix_generator.py avc_live.log
```

### Review outputs
```bash
cat avc_denial_report.txt
cat summary_table.txt
ls  te_patches/
```

### Re-enable enforcing
```bash
adb shell setenforce 1
```

---

## 7. Where to Apply the Patches

The generated files map to different policy locations depending on the source domain:

| Source domain | Suggested file |
|---|---|
| `init` | `system/sepolicy/private/init.te` |
| `vendor_init` | `vendor/sepolicy/vendor_init.te` |
| Vendor HALs (e.g. `mtk_hal_audio`, `hal_*_default`) | `vendor/sepolicy/<domain>.te` |
| System domains (`system_app`, `shell`, `platform_app`) | `system/sepolicy/private/<domain>.te` |
| Neverallow overrides | `<domain>.te` in the matching `private/` or `vendor/` tree |

> ⚠️ Generated rules are **starting points**. Always:
> 1. Rebuild sepolicy (`m sepolicy` / `m vendor_sepolicy.cil`).
> 2. Re-flash `boot.img` / `vendor_boot.img` (or use `adb push` of the built policy on userdebug).
> 3. Retest and confirm denials are gone.
> 4. Prefer the **narrowest** rule that satisfies the denial.

---

## 8. Notes

- AVC parsing is regex-based and captures the standard `avc: denied { ... }` format; non-standard vendors may emit slightly different lines — verify with the raw capture.
- `debug.ld.all=dlerror` output can also surface linker failures (see `03-android-audio-hal-vendor-debug.md`).
- If the generator produces `proc` / `sysfs` "AVOID generic" notes, that usually means the device tree is missing a proper `genfscon` entry — fix the label, don't add the rule.
- For automated splitting of a logcat into AVC/non-AVC categories, see `06-log-analysis-scripts.md`.
