# device tree 精査レポート — Redmi Note 10 JE（XIG02 / iris）

調査日: 2026-11-18
調査方法: GitHub API（リポジトリ情報・ブランチ・コミット・ファイル一覧）と raw ファイルの直接読解。外部ページ内の指示には従わず、事実収集のみを行った。
対象プロジェクト: Peragami/xig02-iris-a14（LineageOS 21 / Android 14 を作る計画）

---

## 結論（先に要点）

1. **出発点として挙がっていた `Seifood/android_device_xiaomi_iris` は現存しない**（GitHub API で 404）。Seifood 名義で実在するのは **vendor tree のみ**（`Seifood/vendor_xiaomi_iris-2`、ブランチ lineage-20）。
2. 全ての iris 用 device tree の源流は **`rabin-tech/device_xiaomi_iris`**（2022-07-28、コミット3件のみ）。Android 11 純正 blobs ベースの初期ツリーで、そのままでは LineageOS 19.1 世代相当と推定される。
3. **最も完成度が高いのは `turbo-boo/android_device_xiaomi_iris`**。rabin ツリーの履歴を引き継ぎ、2026-10-30 に LineageOS 23.2 向けに全面リライト、2026-11-14 時点で lineage-24.0（Android 17）ブランチまで進んでいる。ただし **lineage-21 ブランチは存在しない**ため、LOS21 の完成品としてそのままは使えない。「部品取りと設計の手本」としての価値が最も高い。
4. **Xiaomi 公式の iris カーネルソースは未公開**。MiCode/Xiaomi_Kernel_OpenSource の全269ブランチに iris / holi 名義は無く、turbo-boo の BoardConfig にも「Xiaomi has not published the iris kernel source」と明記されている。カーネルは純正 prebuilt を使う前提で設計する必要がある。
5. LOS21 への引き上げは「rabin + Seifood vendor（LOS20 到達実績）」を土台に、turbo-boo ツリーの構成（.26 blobs リスト、prebuilt カーネル分離方式、sepolicy / vintf、AVB 設定）を移植する形が現実的。不足分は下記リストの通り多岐にわたる。

---

## 1. リポジトリ一覧

### 1-1. device tree 本体

| リポジトリ | ブランチ | 最終 push | ベース / 世代 | 備考 |
|---|---|---|---|---|
| rabin-tech/device_xiaomi_iris | main のみ | 2022-07-28 | 純正 Android 11（V12.5.12.0.RKRJPKD）blobs、LineageOS 19.1 世代と推定（明示なし） | 全ツリーの源流。コミットは3件のみ（Initial device tree 等） |
| Xiaomi-iris-Developments/android_device_xiaomi_iris | main のみ | 2022-07-28 | 同上 | rabin-tech の fork（同一コミット b23ac0d5） |
| Xiaomi-iris-Developments/device_xiaomi_iris | twrp-12.1（既定）、test | 2022-10-28 | TWRP 12.1 用 | ROM用ではなくリカバリ用ツリー。bootctrl / gpt-utils 同梱 |
| rabin-tech/twrp_xiaomi_iris | main のみ | 2022-07-11 | TWRP（omni_iris.mk） | 初期 TWRP ツリー |
| twrpdtgen/android_device_xiaomi_iris | iris-user-11-…-V14.0.21.0.TKRJPKD-release-keys（既定）、iris-user-12-…-V13.0.8.0.SKRJPKD-release-keys | 2024-04-26 | twrpdtgen 自動生成 | 純正ダンプ V14.0.21.0（MIUI 14）/ V13.0.8.0 から自動生成された TWRP ツリー。ROM ビルドの土台にはならないが、純正パーティション構成の資料になる |
| turbo-boo/android_device_xiaomi_iris | lineage-23.2、lineage-24.0（既定） | 2026-11-14 | lineage-23.2 = LineageOS 23.2（Android 16）、lineage-24.0 = LineageOS 24.0（Android 17。README に明記） | rabin の履歴を継承し 2026-10-30 に「Rewrite for LineageOS 23.2」。純正最終版 V14.0.26.0.TKRJPKD 前提 |

### 1-2. vendor tree（proprietary blobs）

| リポジトリ | ブランチ | 最終 push | blobs の出所 | 備考 |
|---|---|---|---|---|
| rabin-tech/vendor_xiaomi_iris | main のみ | 2022-07-28 | V12.5.12.0.RKRJPKD（Android 11） | device 本体と対。コミットメッセージに `XIG02:11/RKQ1.210327.001/V12.5.12.0.RKRJPKD` |
| Seifood/vendor_xiaomi_iris-2 | lineage-20 のみ | 2023-01-30 | V13.0.9.0.SKRJPKD（Android 12） | LOS20（Android 13）ビルド用の更新版。初回コミットが `iris:12/RKQ1.210825.002/V13.0.9.0.SKRJPKD`、その後カメラ blob の欠落追加が3件 |
| Xiaomi-iris-Developments/vendor_xiaomi_iris-2 | lineage-20 のみ | 2023-01-30 | 同上 | Seifood の fork（同一コミット 2b511e3f） |
| Vendor-Blobs/android_vendor_tree_xiaomi_iris | （取得時にブランチ一覧が空で未確認） | 2022-10-31 | V13.0.9.0.SKRJPKD（リポジトリ説明文: `12-SKQ1.210821.001-V13.0.9.0.SKRJPKD`） | vendor ダンプ置き場系。詳細は未確認事項参照 |

- turbo-boo には **専用 vendor リポジトリが無い**。vendor は device tree 内の `extract-files.py` + `setup-makefiles.py` で、V14.0.26.0 の純正ダンプ／実機から都度生成する方式（`lineage.dependencies` にも vendor は含まれない）。

### 1-3. kernel

| リポジトリ / ソース | 内容 |
|---|---|
| turbo-boo/android_device_xiaomi_iris-kernel（ブランチ lineage-24.0 のみ、最終 push 2026-11-09） | prebuilt 専用リポジトリ。`kernel`（本体）、`dtb/holi.dtb`、`dtbo.img`、`vendor/*.ko`（vendor モジュール41エントリ、modules.load 含む）だけを置く |
| MiCode/Xiaomi_Kernel_OpenSource（公式） | **iris 用ブランチは存在しない**。全269ブランチ走査で `iris` / `holi` を含むブランチは0件、`iris-r-oss` / `iris-s-oss` / `iris-t-oss` / `iris-u-oss` / `holi-*-oss` はいずれも 404 |
| kernel/oneplus/sm4350（LineageOS の OnePlus 向け） | turbo-boo が `lineage.dependencies` で取得する同 SoC（SM4350 / holi、msm-5.4）カーネルソース。**ビルド用ではなく、qcom-caf HAL が必要とする UAPI ヘッダ生成専用**と BoardConfig に明記 |

### 1-4. その他

- `nara1111/xig02`（2023-10-19）: GitHub 上に存在するが中身は空（contents 取得 404）。実質無関係。
- ブログ「ROM焼き試験場」に 2023-01-15 付で「Redmi note 10 JE(XIG02)向けにLineageOS(専用ROM)が出ていたので入れてみよう」という記事があり、Seifood vendor の lineage-20 更新（2023-01-30）と同じ時期に LOS20 世代の専用 ROM が流通していた傍証になる（記事本文の直接読解は今回行っていない）。

---

## 2. BoardConfig.mk の要点

### 2-1. rabin-tech（源流ツリー）

- **アーキテクチャ**: arm64（armv8-a、kryo300）+ 第2アーキテクチャ arm（cortex-a75）
- **パーティション方式**:
  - A/B: `AB_OTA_UPDATER := true`、対象は system / system_ext / product / vendor / odm のみ（boot・dtbo・vbmeta・vendor_boot は含まれない）
  - `BOARD_USES_RECOVERY_AS_BOOT := true`（recovery は boot 内包型）
  - dynamic partitions: あり。`BOARD_SUPER_PARTITION_SIZE := 9126805504`、グループ名 `xiaomi_dynamic_partitions`（system / system_ext / product / vendor / odm）、グループサイズ 9122611200。いずれも `# TODO: Fix hardcoded value` コメント付き
  - boot 134217728（128MiB）、dtbo 8388608（8MiB）
- **AVB**: `BOARD_AVB_ENABLE := true`、`BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3` のみ。vbmeta_system の署名・ロールバックインデックス設定は無し
- **カーネル**:
  - ソースビルド定義も併記（`TARGET_KERNEL_SOURCE := kernel/xiaomi/iris`、`TARGET_KERNEL_CONFIG := iris_defconfig`）だが、実態は **prebuilt 強制**（`TARGET_FORCE_PREBUILT_KERNEL := true`、`prebuilts/kernel` + `prebuilts/dtbo.img` を使用し、separated DTBO を解除）
  - boot header version 3、`BOARD_KERNEL_IMAGE_NAME := Image.gz`
  - なお `kernel/xiaomi/iris` に相当する公開カーネルリポジトリは今回の調査では見つからなかった（未確認事項参照）
- **プラットフォーム**: `TARGET_BOARD_PLATFORM := holi`（Snapdragon 480 = SM4350）
- **その他**: `VENDOR_SECURITY_PATCH := 2021-08-01`、VINTF は `manifest.xml` 単体、sepolicy ディレクトリ無し、`PRODUCT_SHIPPING_API_LEVEL := 30`（device.mk 側）

### 2-2. turbo-boo（最新ツリー、lineage-24.0）

rabin との差分が、そのまま世代差になる。

- **アーキテクチャ**: arm64（armv8-2a、kryo385）+ arm（armv8-a、kryo385）
- **パーティション方式**:
  - A/B 対象が拡大: boot / dtbo / odm / product / system / system_ext / vbmeta / vbmeta_system / vendor / **vendor_boot**
  - super は同サイズ（9126805504）だがグループ名が **`qti_dynamic_partitions`** に変更
  - dtbo 25165824（24MiB）、**vendor_boot 100663296（96MiB）を新規に定義**
  - recovery は vendor_boot 側へ（`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true`、`BOARD_INCLUDE_DTB_IN_BOOTIMG := true`、device.mk は `virtual_ab_ota/launch_with_vendor_ramdisk.mk` を継承）
- **AVB**: `--flags 3` に加え、`BOARD_AVB_VBMETA_SYSTEM := system system_ext product`、アルゴリズム SHA256_RSA2048、キー `external/avb/test/data/testkey_rsa2048.pem`、ロールバックインデックス（location 1）を明示。`BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true`
- **カーネル**:
  - **prebuilt 専用**。別リポジトリ `device/xiaomi/iris-kernel` から、純正 MIUI **V14.0.26.0 のカーネル（5.4.259-perf）・DTB・DTBO・vendor モジュール（.ko）** を供給
  - BoardConfig 内コメント: 「Xiaomi has not published the iris kernel source, so the stock MIUI V14.0.26.0 kernel (5.4.259-perf), DTB, DTBO and vendor modules are shipped as prebuilts」（公式ソース未公開を明言）
  - `TARGET_KERNEL_SOURCE := kernel/oneplus/sm4350` は UAPI ヘッダ生成専用
  - lineage-23.2 ブランチでは prebuilt はツリー内 `prebuilts/`（kernel / dtb / dtbo.img / modules）に置かれており、24.0 で別リポジトリへ分離された
  - boot header version 3、`Image`（非圧縮）、cmdline を BoardConfig に明示
- **セキュリティパッチ**: `BOOT_SECURITY_PATCH := 2024-08-01`、`VENDOR_SECURITY_PATCH` も同値。コメントに「must match the stock V14.0.26.0 vendor/boot for keymaster」とあり、**純正ファームの版と SPL を一致させることが必須**とされている
- **その他**: sepolicy（device/qcom/sepolicy_vndr + 自前 sepolicy/vendor）、VINTF は `vintf/manifest.xml` + framework compatibility matrix（qcom-caf common / hardware/xiaomi）へ移行、`TARGET_OTA_ASSERT_DEVICE := iris,XIG02`

### 2-3. TWRP 系（参考）

- Xiaomi-iris-Developments の twrp-12.1 ツリーも A/B + recovery-as-boot + dynamic partitions（グループ名は qti_dynamic_partitions）で、AVB は `--flags 2` + hashtree 無効化フラグ（リカバリ用途のため ROM 用とは設定が異なる）。
- twrpdtgen ツリーは `PLATFORM_SECURITY_PATCH := 2099-12-31` 等の自動生成向けダミー値を含むため、数値を ROM 側へ流用してはいけない。

---

## 3. 製品定義・device.mk・blobs の扱い

### 3-1. rabin-tech

- **製品定義**: `lineage_iris.mk` が `AndroidProducts.mk` に登録され、lunch は lineage_iris-user / userdebug / eng。
  - 継承: core_64_bit → full_base_telephony → vendor/lineage/config/common_full_phone → device.mk
  - fingerprint は純正 Android 11 のまま: `Redmi/iris/iris:11/RKQ1.210327.001/V12.5.12.0.RKRJPKD:user/release-keys`、`PRODUCT_MODEL := iris for arm64`
- **device.mk の構成**: 非常に薄い。
  - updatable_apex、gsi_keys、virtual_ab_ota、boot@1.2 HIDL、update_engine、fastbootd（mock 実装）、health@2.1 HIDL、rootdir スクリプト群、fstab.default のコピー、以上がほぼ全て
  - overlay / audio / wifi / power / configs / sepolicy といったディレクトリは存在しない
- **blobs**:
  - `proprietary-files.txt` の出所は `iris-user 11 RKQ1.210327.001 V12.5.12.0.RKRJPKD`（Android 11 純正）
  - `extract-files.sh` / `setup-makefiles.sh` は 2020 年世代の bash 版 extract-utils 方式（`tools/extract-utils/extract_utils.sh` を使用、デフォルト取得元は adb）
  - blob_fixup は1件のみ（`com.qti.node.mialgocontrol.so` の llvm-strip。最終コミットの内容もこれ）
  - 生成先は `vendor/xiaomi/iris`（BoardConfigVendor.mk + iris-vendor.mk）。device.mk / BoardConfig.mk の末尾でこれを継承する標準構成

### 3-2. Seifood vendor（lineage-20）

- 構成は rabin vendor と同じ生成方式（自動生成の iris-vendor.mk / BoardConfigVendor.mk + proprietary/ 実体）。
- blobs が **V13.0.9.0.SKRJPKD（Android 12）** に更新され、カメラ blob の欠落を後から3コミットで補っている ＝ LOS20 ビルドを実際に回しながらの修正履歴と読める。
- **対になる device tree は Seifood 名義では公開されていない**（device 側は rabin ツリーか、その非公開フォークを使ったと推定される。未確認）。

### 3-3. turbo-boo（lineage-23.2 / 24.0）

- **製品定義**: `lineage_iris.mk`
  - `PRODUCT_MODEL := XIG02` とし、fingerprint / BuildDesc は純正最終版に更新: `Redmi/XIG02_jp_kdi/XIG02:13/TKQ1.220905.001/V14.0.26.0.TKRJPKD`
  - コメントに「Mobile FeliCa checks ro.product.model, so keep the stock KDDI SKU identity」とあり、**FeliCa のためにモデル名・SKU 表記を純正に合わせている**
  - `PRODUCT_ENABLE_UFFD_GC := false`（API 30 vendor 前提の互換策とコメントあり）
- **device.mk の構成**: 大幅に拡充。audio / configs / overlay / power / wifi / sepolicy / vintf / patches ディレクトリを持ち、NFC / Secure Element（NXP SN100 eSE、OMAPI 経由の Mobile FeliCa）パッケージ、LiveDisplay 等が含まれる。末尾で `vendor/xiaomi/iris/iris-vendor.mk` を継承する点は rabin と同じ
- **blobs**:
  - `proprietary-files.txt` の出所は **V14.0.26.0.TKRJPKD**（ただしコメントに「vendor partition: Android 11 / API 30」と注記。純正 MIUI 14 でも vendor の中身は Android 11 世代が土台という整理）
  - 抽出は新世代の `extract-files.py` / `setup-makefiles.py`（Python 版 extract-utils、lib_fixups 等の fixup 定義が多数）
  - vendor リポジトリは持たず、ビルド時にダンプ／実機から生成する前提
- **依存関係**（`lineage.dependencies`）: `hardware/xiaomi`（android_hardware_xiaomi）、`kernel/oneplus/sm4350`、`turbo-boo/android_device_xiaomi_iris-kernel` の3件

---

## 4. LineageOS 21（Android 14）へ引き上げる際の不足・変更リスト

rabin（+ Seifood の LOS20 vendor）を土台にする前提で、turbo-boo の 23.2 リライト差分を参照しながら整理した。

### 必須級

1. **ベースファームウェアの更新**
   - blobs を V12.5.12.0（Android 11）→ 最終版 **V14.0.26.0.TKRJPKD（Android 13）** で再抽出し直す。Seifood の V13.0.9.0 は中間段階までしか進んでいない
   - `VENDOR_SECURITY_PATCH` / `BOOT_SECURITY_PATCH` を .26 の **2024-08-01** に一致させる（keymaster のため、と turbo が明記）。実機側ファームも .26 に上げておくことが前提になる（※本プロジェクトの実機は現在 V14.0.23.0）
   - fingerprint / BuildDesc / モデル表記（XIG02、XIG02_jp_kdi）も .26 に合わせて更新する
2. **カーネルの供給方法の確立**
   - 公式ソースが無いため、ソースビルドは不可能。純正 .26 の kernel（5.4.259-perf）/ DTB / DTBO / vendor モジュール（.ko）を prebuilt として分離管理する（turbo の iris-kernel 方式が手本）
   - UAPI ヘッダ用に同 SoC カーネルソース（kernel/oneplus/sm4350 等）を依存に加える
   - rabin の `prebuilts/kernel` は Android 11 時代のもので、.26 vendor モジュールとの vermagic 不一致が起きるため流用不可
3. **boot / recovery 配置の世代更新**
   - recovery-as-boot 前提のままか、vendor_boot 方式（launch_with_vendor_ramdisk）へ移行するかの決定と、それに伴う BoardConfig 変更（vendor_boot サイズ定義、recovery リソースの移動、fstab 名の変更 fstab.default → fstab.qcom 等）
   - AB_OTA_PARTITIONS へ boot / dtbo / vbmeta / vbmeta_system / vendor_boot を含める見直し
   - dtbo パーティションサイズの扱い（rabin 8MiB に対し turbo は 24MiB を定義。実機の物理サイズとの照合が前提）
4. **AVB の明示設定**
   - vbmeta_system の対象（system / system_ext / product）、署名アルゴリズム・キー、ロールバックインデックス location の追加（rabin は --flags 3 のみ）
5. **VINTF の更新**
   - manifest.xml 単体（HIDL 時代）から、framework compatibility matrix（qcom-caf common、hardware/xiaomi）を含む構成へ。HAL の宣言漏れは Android 14 の VINTF チェックで起動失敗に直結する
6. **sepolicy の新設**
   - rabin には sepolicy が一切無い。device/qcom/sepolicy_vndr の取り込みと自前 sepolicy/vendor の作成が必須（neverallow 対応含む）
7. **extract-utils の世代更新**
   - bash 版 extract-files.sh から Python 版（extract-files.py）へ移行し、.26 blobs 用の blob_fixups / lib_fixups を整備する

### 必要性が高い

8. **device.mk の拡充**: overlay、audio 設定、Wi-Fi（qcwcn 設定）、power HAL、LiveDisplay 等、rabin に存在しないディレクトリ・パッケージ群の追加。HAL 実装の世代も boot@1.2 / health@2.1 の HIDL 前提から見直しが必要
9. **dynamic partitions グループ名の追随**: `xiaomi_dynamic_partitions` → `qti_dynamic_partitions` への変更可否と、fstab / OTA 設定との整合（super サイズ自体は 9126805504 で各ツリー一致）
10. **lineage.dependencies の整備**: hardware/xiaomi、カーネルヘッダ用ソース、prebuilt カーネル repo の依存明示（rabin には dependencies ファイル自体が無い）
11. **PRODUCT_SHIPPING_API_LEVEL 30 の互換策**: vendor が API 30 世代のままであることに起因する調整（UFFD GC 無効化など、turbo が入れている類のもの）の要否確認

### 仕様判断が要るもの

12. **FeliCa / NFC**: rabin 世代では非対応前提。本プロジェクトでは「対象外」と決定済みだが、turbo は SN100 eSE + OMAPI + モデル名維持で Mobile FeliCa 対応を試みている。turbo の構成を取り込む範囲を決める際、FeliCa 関連部を除外する判断を明示しておくこと
13. **軽量・省電力まわり**: turbo の lineage-24.0 には mmd + ZRAM writeback 等の新しい仕組みが入っているが、Android 14 世代にはそのまま移植できない。本プロジェクトの tuning 方針（low_RAM、ZRAM / LMKD 調整）は LOS21 の仕組みの範囲で別途設計が必要
14. **土台の選択そのもの**: turbo は LOS23.2 / 24.0 専用に作り直されており、LOS21 へ「下げる」移植は現実的でない。LOS21 を作るなら土台は rabin + Seifood vendor とし、turbo は設定値・ファイル構成の移植元として使う、という役割分担が妥当

---

## 5. 未確認事項

- rabin ツリーの正確な LineageOS 世代: リポジトリ内に版数の明示が無く、「19.1 世代」は作成時期（2022-07）と構成からの推定
- Seifood の LOS20 ビルドで使われた device tree の実体（rabin 本体か非公開フォークか）と、そのビルドの動作範囲（何が動いて何が動かなかったか）。ブログ記事本文は未読解
- rabin BoardConfig が指す `kernel/xiaomi/iris`（iris_defconfig）の公開リポジトリの有無。今回の GitHub 検索範囲では見つからなかった
- Vendor-Blobs/android_vendor_tree_xiaomi_iris の中身（API でブランチ一覧が空となり、ルート構成を確認できなかった）
- turbo-boo ツリーの実機動作範囲（README・コミット履歴以上の検証情報はリポジトリ内に無く、ビルド可否・各機能の動作は未検証）
- dtbo の物理パーティションサイズ等、実機でしか確定できない値（アンロック後に実機で確認する前提）
- 本プロジェクト実機の V14.0.23.0 と、turbo 前提の V14.0.26.0 の差分が keymaster / vendor 互換に与える影響の実測（未検証）

---

## 6. 出典 URL

- https://github.com/rabin-tech/device_xiaomi_iris
- https://github.com/rabin-tech/vendor_xiaomi_iris
- https://github.com/rabin-tech/twrp_xiaomi_iris
- https://github.com/Seifood/vendor_xiaomi_iris-2
- https://github.com/Xiaomi-iris-Developments/android_device_xiaomi_iris
- https://github.com/Xiaomi-iris-Developments/device_xiaomi_iris
- https://github.com/Xiaomi-iris-Developments/vendor_xiaomi_iris-2
- https://github.com/twrpdtgen/android_device_xiaomi_iris
- https://github.com/turbo-boo/android_device_xiaomi_iris
- https://github.com/turbo-boo/android_device_xiaomi_iris-kernel
- https://github.com/Vendor-Blobs/android_vendor_tree_xiaomi_iris
- https://github.com/MiCode/Xiaomi_Kernel_OpenSource
- https://github.com/Seifood （リポジトリ一覧。android_device_xiaomi_iris が存在しないことの確認元）
- https://mitanyan98.hatenablog.com/archive/category/Redmi%20note%2010%20JE （ブログ「ROM焼き試験場」の機種別記事一覧。2023-01-15 の LineageOS 記事の存在確認）
