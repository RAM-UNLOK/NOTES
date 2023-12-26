#  Bitra Project Blaze Device,Vendor,Kernel,Hardwareoplus Trees

>  Build By : [Omkar Parte](https://t.me/rakmoparte) ( RAKMOSOLUTIONS )


## Configure Git

```
git config --global user.name "RAM-UNLOK"
```
```
git config --global user.email rakmoparte@gmail.com
```


## Clone repos (Project Blaze Bringup)

```
git clone https://github.com/RAM-UNLOK/android_device_realme_sm8250-common.git -b A14 device/realme/sm8250-common
```
```
git clone https://github.com/RAM-UNLOK/android_device_realme_bitra.git -b A14 device/realme/bitra
```
```
git clone https://github.com/RAM-UNLOK/android_hardware_oplus.git -b A14 hardware/oplus
```
```
git clone https://github.com/RAM-UNLOK/kernel_realme_sm8250.git -b bigshot-AOSP kernel/realme/sm8250
```
```
git clone https://github.com/RAM-UNLOK/android_vendor_realme_sm8250-common.git -b A14 vendor/realme/sm8250-common
```
```
git clone https://github.com/RAM-UNLOK/android_vendor_realme_bitra.git -b A14 vendor/realme/bitra
```


## Depth 1 Clone repos (Project Blaze Bringup)

```
git clone --depth 1 https://github.com/RAM-UNLOK/android_device_realme_sm8250-common.git -b A14 device/realme/sm8250-common
```
```
git clone --depth 1 https://github.com/RAM-UNLOK/android_device_realme_bitra.git -b A14 device/realme/bitra
```
```
git clone --depth 1 https://github.com/RAM-UNLOK/android_hardware_oplus.git -b A14 hardware/oplus
```
```
git clone --depth 1 https://github.com/RAM-UNLOK/kernel_realme_sm8250.git -b bigshot-AOSP kernel/realme/sm8250
```
```
git clone --depth 1 https://github.com/RAM-UNLOK/android_vendor_realme_sm8250-common.git -b A14 vendor/realme/sm8250-common
```
```
git clone --depth 1 https://github.com/RAM-UNLOK/android_vendor_realme_bitra.git -b A14 vendor/realme/bitra
```

- To Update trees which were cloned with depth=1 use below

```
git pull -f --depth=1 --rebase
```


## Some Tweaks For Building the ROM

- Build BCR (add this to your blaze_device.mk)
- Thanks to [chenxiaolong](https://github.com/chenxiaolong)

```
git clone https://gitlab.com/ram-unlok/bcr.git vendor/bcr
```
```
$(call inherit-product, vendor/bcr/bcr.mk)
```

- Build VIPERFX RE for Blaze
- Thanks to [TogoFire](https://github.com/TogoFire)

```
git clone --depth 1 https://github.com/TogoFire/packages_apps_ViPER4AndroidFX.git packages/apps/ViPER4AndroidFX
```
```
$(call inherit-product, packages/apps/ViPER4AndroidFX/config.mk)
```

- Change Build Time and Date to Indian time
- Replace `date -u` in `vendor/blaze/config/version.mk` with

```
TZ=IST-5:30 date
```

- Basic Commands for start building

> Build using less space and network bandwidth

```
repo init --depth=1 -u https://github.com/RAM-UNLOK/blaze-manifest.git -b 14
```
```
repo sync -c -j$(nproc --all) --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune && repo forall -c git lfs pull
```
```
. build/envsetup.sh
```
```
lunch blaze_$device-userdebug
```
```
make bacon
```

## Update Vendor Blobs From Dump

- Lets Extract Dump from OTA

> [Derailed Guide is here](https://baalajimaestro.me/posts/extract-vendor-2/)

```
git clone https://github.com/RAM-UNLOK/dumpyara.git
```
```
cd dumpyara
```
```
bash setup.sh
```
```
bash dumpyara.sh /otazippathname.zip
```
```
git clone https://github.com/LineageOS/android_tools_extract-utils -b lineage-21.0 android/tools/extract-utils
```
```
git clone https://github.com/LineageOS/android_prebuilts_extract-tools -b lineage-21.0 android/prebuilts/extract-tools
```

- move to you device tree where extract-files.sh is located

```
bash extract-files.sh /otadumppath/
```
- ( usually home/username/dumpyara/working/otazippathname/ )

```
python3 reorder-libs.py
```
- (rearanges files in proprietary-files)

```
sort proprietary-files.txt | uniq -cd | sort -nr
```
- (Finds Duplicate in proprietary-files.txt)


## Grep Commands

```
grep -r filename
```
- (Do to the dir where you want to search for and then use the above command)


## Fix Sepolicy

Download Fix from [Dexer125/SELinux-Denials-Tool](https://github.com/Dexer125/SELinux-Denials-Tool/releases) or [DarkJoker360/selinux-denial-fixer](https://github.com/DarkJoker360/selinux-denial-fixer.git)

```
java -jar SELinuxDenialsTool.jar
```
```
python3 denials.py
```

## Find and replace one word from multiple dir

```
grep -rli 'EXPORT_SYMBOL' | xargs sed -i 's/EXPORT_SYMBOL(/EXPORT_SYMBOL_GPL(/g'
```
