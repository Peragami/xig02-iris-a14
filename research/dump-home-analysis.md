# dump-home 解析結果（2026-11-26）

自宅で再ダンプした dump-home をギガファイル便で受け取り、むぜのVMで解析した結果。
転送ファイル: 4,098,256,215 バイト（7z形式、中身は dump-home フォルダ一式）

## 検証

- manifest.txt（78パーティション分）と全 .img を SHA-256 照合: **78/78 一致、不一致・欠落ゼロ**
- 主要ハッシュは学校ダンプ（dump2）と完全一致し、2回の独立ダンプの同一性を実証
  - boot_b: 4ffcb748bcd94c615c298af7c5d80d247d7276b4d64f353e625724249071b39c
  - super: 75833a424ddcf6d71475d90db4b53f1e707f278640ca7b537ecd1da5eccf1eb0
  - vendor_boot_a: aec504886b1c2dfaa6d018362c42e3fc073c6caf5a1dc5d60e20f81294e26ebd
  - vendor_boot_b: 3efad29cee55f5f14210b257988df8b4b1b09669b1ef913aebf8be3c96dc5d68
- 既知の欠陥は従来通り super 内 product 領域の読み取りエラー2件のみ（ゼロ埋め）

## boot_b（純正カーネル）

- boot image header v3、kernel 43,082,240 バイト、ramdisk 19,749,596 バイト
- **カーネル: Linux 5.4.233-perf-g00e5f082d2b8**
  - .26 純正の 5.4.259 ではない。プランBではこの 5.4.233 を prebuilt として使うこと
- os_version フィールド: Android 11.0.0 / SPL 2024-04（vendor 世代が Android 11 のため。後述）

## vendor_boot_b

- vendor boot header v3、page 4096、vendor ramdisk 641,815 バイト（gzip cpio、展開時 2,832,896 バイト）
- DTB 327,507 バイト、所定オフセット（647,168）にマジック d00dfeed を確認
- DTB の SoC 表記: **Qualcomm Technologies, Inc. Holi SoC**（Snapdragon 480 / SM4350、GPU は Adreno 619）
- カーネルモジュールは lib/modules/5.4-gki/ 配下（gcc-holi, pinctrl-holi, qnoc-holi 等 holi 系）
- cmdline: androidboot.hardware=qcom、usbcontroller=4e00000.dwc3 等
- first_stage_ramdisk/fstab.default を回収:
  - 動的パーティション: system / system_ext / product（avb=vbmeta_system）、vendor / odm（avb）、mi_ext（avb=vbmeta、/mnt/vendor/mi_ext へマウント後に /mi_ext へ bind）
  - userdata は f2fs + FBE（aes-256-xts、wrappedkey_v0、inlinecrypt）
  - metadata は ext4 で first_stage_mount

## super（論理パーティション構成）

- liblp メタデータはスロット別に3コピーあり、内容が異なる（QTI方式）
  - copy0: スロットA用フル構成（OTA .26 の書き込み先だった側。system_a-cow 等あり）
  - copy1: スロットB用フル構成（現行 .23）
  - copy2: 両スロット併記（_b 側は extent 0 のプレースホルダ）
- スロットB（.23）のサイズ:
  - system_b 1,345,859,584 / system_ext_b 801,558,528 / product_b 4,157,960,192
  - vendor_b 1,298,329,600 / odm_b 1,355,776 / mi_ext_b 282,624
  - system_b-cow 1,312,530,432 / system_ext_b-cow 206,045,184 も存在

## ビルド情報（実物 build.prop から確認）

- system: **V14.0.23.0.TKRJPKD**、Android 13、TKQ1.220905.001、**SPL 2024-04-01**、ビルド日 2024-04-09
  - system fingerprint: qti/missi/missi:13/TKQ1.220905.001/V14.0.23.0.TKRJPKD
- product: MIUI V140、fingerprint は Xiaomi/miproduct_iris_jp_kd（jp_kd = KDDI向け）
- vendor: **Android 11 世代**（RKQ1.210825.002）、fingerprint は Redmi/XIG02_jp_kdi/XIG02:11/... と Redmi/iris/iris:11/... の2種、vendor SPL 2024-04-01

## プランBへの含意

- 土台は V14.0.23.0 で確定（実物で再確認済み）
- prebuilt カーネルは boot_b の **5.4.233** を使う。.26 前提の device tree（turbo-boo 等）はカーネル・blobs を全て .23 に読み替える必要がある（従来方針通り）
- vendor が Android 11 世代のため、新しめの vendor を前提にしたツリーとは互換性に注意
- 復旧用ダンプは dump2（学校ノート）＋ dump-home（自宅PC）＋ むぜVM の3部体制になった
