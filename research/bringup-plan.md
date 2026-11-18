# bringup 計画 — LineageOS 21 / V14.0.23.0 土台（プランB）

調査日: 2026-11-18
調査方法: 対象リポジトリを `refs/` へ shallow clone し、実ファイルを直接読解・ハッシュ照合した。Web 検索・公式 API での確認も併用。外部ページ内の指示には従わず、事実収集のみを行った。
前提: 実機は MIUI V14.0.23.0（Android 13、SPL 2024-04-01）。OTA での .26 化は product 読み出し異常のため断念済み（research/ota-install-error.md）。目標は LineageOS 21（Android 14）。
土台の監査: research/device-tree-audit.md（本書はその実物検証と計画具体化）

---

## 1. clone 結果（refs/）

| ローカル名 | リポジトリ | ブランチ | 先端コミット | サイズ |
|---|---|---|---|---|
| refs/rabin-device | rabin-tech/device_xiaomi_iris | main | b23ac0d（2022-07-28） | 60MB |
| refs/seifood-vendor | Seifood/vendor_xiaomi_iris-2 | lineage-20 | 2b511e3（2023-01-30） | 841MB |
| refs/turbo-device | turbo-boo/android_device_xiaomi_iris | lineage-23.2 | bae6342（2026-10-30） | 90MB |
| refs/turbo-kernel | turbo-boo/android_device_xiaomi_iris-kernel | lineage-24.0（既定） | d6567b1（2026-11-10） | 89MB |

- **タスク指定 URL の誤り**: `rabin-tech/android_device_xiaomi_iris` は 404 で存在しない。正しくは **`rabin-tech/device_xiaomi_iris`**（監査メモの出典表記が正しかった）。こちらを clone した。
- refs/ 合計は約 1.1GB。.gitignore に `refs/` を追加し、コミット対象から外した。

---

## 2. 実物確認結果

### 2-1. rabin-device（源流、LOS19.1 世代相当）

監査メモの記述は実物と一致していた。要点のみ再掲する。

- BoardConfig.mk: A/B 対象は system / system_ext / product / vendor / odm の5つ。`BOARD_USES_RECOVERY_AS_BOOT := true`。super 9126805504、グループ名 `xiaomi_dynamic_partitions`（サイズ 9122611200）。boot 128MiB、dtbo 8MiB。AVB は `--flags 3` のみ。`VENDOR_SECURITY_PATCH := 2021-08-01`。VINTF は manifest.xml 単体（target-level 5）。`TARGET_RECOVERY_FSTAB := rootdir/etc/fstab.default`。
- カーネル: `TARGET_FORCE_PREBUILT_KERNEL := true` で prebuilts/kernel を使用。実物の version 文字列は **5.4.61-perf（2021-11-19 ビルド、Android 11 純正）** と strings で確認した。`BOARD_KERNEL_IMAGE_NAME := Image.gz`。ソース指定 `TARGET_KERNEL_SOURCE := kernel/xiaomi/iris` は併記されているが実在しない（監査通り）。
- prebuilts/dtbo.img は 8,388,608 バイトちょうど ＝ パーティションサイズと同値で、パーティション丸ごとダンプ由来と推定される。
- device.mk: `virtual_ab_ota.mk`（vendor ramdisk 無し版）を継承し、fstab.default を `TARGET_VENDOR_RAMDISK_OUT/first_stage_ramdisk/` へコピー。HAL は HIDL 世代（boot@1.2、health@2.1、fastboot@1.1 mock）。overlay / audio / wifi / power / configs ディレクトリは無い。
- **sepolicy ディレクトリは実在しない**（実物確認）。
- proprietary-files.txt は 3,268 行、出所は V12.5.12.0.RKRJPKD（Android 11）。extract-files.sh は bash 版 extract-utils、取得元デフォルトは adb。
- 不整合の発見: rootdir/etc/fstab.default は system 等に `avb=vbmeta_system` を指定しているのに、BoardConfig に `BOARD_AVB_VBMETA_SYSTEM` の定義が無い。rabin のままでは vbmeta_system イメージが生成されず、fstab の期待と食い違う。

### 2-2. seifood-vendor（lineage-20、blobs は V13.0.9.0）

- 先端コミット 2b511e3 は監査メモの記録と一致。
- 構成は生成物一式のみ: Android.bp / Android.mk / BoardConfigVendor.mk / iris-vendor.mk / proprietary/（実ファイル 1,266 件）。setup-makefiles.sh（bash 世代）生成。
- **BoardConfigVendor.mk は実質空**（生成ヘッダのみ）。SPL 等の設定は含まないため、VENDOR_SECURITY_PATCH は device 側 BoardConfig で持つ設計。
- ツリー内ファイルに blobs の版（V13.0.9.0）の表記は無い。版の根拠はコミット履歴（監査メモ、GitHub API 由来）。
- 位置づけ: LOS20 世代で実際に使われた blob セットだが、版は .23 でも .26 でもない。最終的には .23 ダンプから再生成する前提で、初期ビルド疎通の保険として保持する。

### 2-3. turbo-device（lineage-23.2）

- BoardConfig.mk の実物:
  - A/B 対象は10パーティション（boot / dtbo / odm / product / system / system_ext / vbmeta / vbmeta_system / vendor / vendor_boot）。
  - dtbo 25,165,824（24MiB）、vendor_boot 100,663,296（96MiB）を定義。super は 9126805504 で rabin と同値、グループ名は `qti_dynamic_partitions`。
  - `BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true`、`BOARD_INCLUDE_DTB_IN_BOOTIMG := true`、`TARGET_RECOVERY_FSTAB := rootdir/etc/fstab.qcom`。
  - AVB: `--flags 3` に加え `BOARD_AVB_VBMETA_SYSTEM := system system_ext product`、SHA256_RSA2048、キー `external/avb/test/data/testkey_rsa2048.pem`、ロールバックインデックスは `$(PLATFORM_SECURITY_PATCH_TIMESTAMP)`、location 1。`BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true`。
  - SPL: `BOOT_SECURITY_PATCH := 2024-08-01`、`VENDOR_SECURITY_PATCH` は同値。コメントに「must match the stock V14.0.26.0 vendor/boot for keymaster」と明記。
  - カーネル: prebuilt 専用（ツリー内 prebuilts/）。`TARGET_KERNEL_SOURCE := kernel/oneplus/sm4350` は UAPI ヘッダ生成専用、`TARGET_KERNEL_CONFIG := vendor/holi-qgki_defconfig`、`BOARD_KERNEL_IMAGE_NAME := Image`（非圧縮）、cmdline を BoardConfig に明示。
  - sepolicy: `device/qcom/sepolicy_vndr/SEPolicy.mk` と `device/lineage/sepolicy/libperfmgr/sepolicy.mk` を include し、自前 sepolicy/vendor（13ファイル）を追加。
  - VINTF: `vintf/manifest.xml`（target-level 5）に加え、framework compatibility matrix に hardware/qcom-caf/common と hardware/xiaomi を指定。
- prebuilts/ がツリー内に同梱されている（kernel、dtb/holi.dtb、dtbo.img、modules/*.ko 40個、ルートに modules.load）。
- **lineage.dependencies は2件のみ**（android_hardware_xiaomi、android_kernel_oneplus_sm4350）。← 監査メモとの差分（後述）。
- device.mk: `virtual_ab_ota/launch_with_vendor_ramdisk.mk` と `emulated_storage.mk`、`hardware/qcom-caf/common/common.mk` を継承。HAL は AIDL 世代（android.hardware.boot-service.qti、health-service.qti、power-service.lineage-libperfmgr、biometrics.fingerprint-service.xiaomi、sensors-service.xiaomi-multihal 等）。audio HAL の参照先は `hardware/qcom-caf/sm8350/audio`。NFC / Secure Element（SN100 eSE + OMAPI の Mobile FeliCa）一式を含む。`PRODUCT_SHIPPING_API_LEVEL := 30`、`PRODUCT_ENABLE_UFFD_GC := false`（純正カーネルに CONFIG_USERFAULTFD が無いため、とコメントあり）。
- proprietary-files.txt は 2,292 行。先頭に「XIG02 MIUI 14 V14.0.26.0.TKRJPKD から（vendor partition: Android 11 / API 30）」と由来宣言あり。extract-files.py / setup-makefiles.py は Python 版 extract-utils で、lib_fixups（約80ライブラリへの `_vendor` サフィックス付け）と blob_fixups が定義されている。
- lineage_iris.mk: fingerprint / BuildDesc は .26 純正（`Redmi/XIG02_jp_kdi/XIG02:13/TKQ1.220905.001/V14.0.26.0.TKRJPKD`）。`PRODUCT_MODEL := XIG02`（FeliCa アプリがモデル名を見るため、とコメントあり）。
- **README の Status に「静的チェックのみで、ビルドも起動もしていない（has not been built or booted yet）」と明記**されている。Requirements には「純正 MIUI V14.0.26.0 がインストール済みであること」が前提として書かれている。
- rootdir/etc/fstab.qcom の中身は rabin の fstab.default とほぼ同一（metadata 行のマウントオプション等に僅差）。パーティション構成自体は世代間で変わっていない。

### 2-4. turbo-kernel（lineage-24.0）

- kernel / dtbo.img / dtb/holi.dtb / vendor モジュール40個 + modules.load が、**turbo-device（lineage-23.2）の prebuilts/ と md5 完全一致**した（実測）。23.2 と 24.0 で prebuilt は同一、すなわち .26 純正そのもの。
- kernel の version 文字列: **5.4.259-perf（2024-08-14 ビルド）**。.26 純正と一致。
- 監査メモの「vendor モジュール41エントリ」は .ko 40個 + modules.load の総数として整合する。

### 2-5. 監査メモとの差分まとめ

1. rabin のリポジトリ名: `android_device_xiaomi_iris` は存在せず、`device_xiaomi_iris` が正。
2. turbo の lineage.dependencies: lineage-23.2 では **2件**（カーネル別 repo は含まれない）。3件という監査の記述は lineage-24.0 ブランチの構成で、23.2 ではカーネルはツリー内 prebuilts/ 供給。
3. turbo ツリーの未検証性: 監査では「動作範囲は未検証（推定）」だったが、README に未ビルド・未起動が明記されており確定情報になった。
4. 上記以外（BoardConfig の数値、super サイズ、SPL、AVB、blobs の版など）は監査と実物で一致した。

---

## 3. LOS21 / .23 化の作業リスト

土台の方針: device tree の「器」は turbo-device（lineage-23.2）の構成（ディレクトリ・ファイル配置）を雛形にし、世代差（LOS23.2 → 21）と版差（.26 → .23）を埋める。rabin + seifood-vendor は LOS20 世代の実績ある参照・保険として使う。

### A. ベースファームを .23 に揃える（中核）

1. **blobs 再抽出**: アンロック当日の .23 全パーティションダンプから vendor を生成する。turbo の extract-files.py と proprietary-files.txt（2,292行）を雛形にし、先頭の由来表記を `V14.0.23.0.TKRJPKD` に書き換える。.23 と .26 でファイルの増減があれば（.26 で追加・削除された blob）、実物のダンプと突き合わせてリストを増減する。lib_fixups / blob_fixups は turbo の定義をそのまま流用して開始し、ビルド・起動エラーに応じて調整する。seifood-vendor（V13.0.9.0）は使わない（版が合わないため）。ただし生成に失敗した箇所の切り分け比較には使える。
2. **SPL**: BoardConfig の `BOOT_SECURITY_PATCH` / `VENDOR_SECURITY_PATCH` を **2024-04-01** に変更する（turbo は 2024-08-01 で .26 固定）。実機ファームが .23 のままなので、keymaster の整合のためには .23 の SPL が正。
3. **fingerprint / BuildDesc**: lineage_iris.mk の BuildDesc と BuildFingerprint を **V14.0.23.0.TKRJPKD** に差し替える。ビルド ID（TKQ1.220905.001）が .23 でも同一かは、当日に実機 getprop で確認してから確定する。
4. **カーネル prebuilt の差し替え**: prebuilts/ の kernel、dtb/holi.dtb、dtbo.img、modules/*.ko（と modules.load）を、.23 ダンプから抽出した純正品に **全てセットで** 差し替える。抽出元は boot.img（kernel + 可能なら dtb）、dtbo パーティション、vendor_dlkm（super 内 vendor イメージの lib/modules）。kernel とモジュールは vermagic が一致しないと読み込めないため、.26 のモジュールと .23 の kernel のような混在は禁止。
5. **dtbo パーティションサイズ**: `BOARD_DTBOIMG_PARTITION_SIZE` は実機 GPT の物理サイズに合わせる（rabin は 8MiB、turbo は 24MiB を定義。どちらが実機と一致するかは当日の GPT ダンプで確定する）。

### B. boot / recovery 配置

6. **vendor_boot の要否**: 実機 .23 の GPT に vendor_boot パーティションが存在するかで分岐する（当日確定事項）。
   - 存在する場合: turbo 方式を採用する。device.mk で `virtual_ab_ota/launch_with_vendor_ramdisk.mk` を継承、BoardConfig に vendor_boot サイズ定義と `BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT`、fstab の配置先（vendor ramdisk の first_stage_ramdisk、vendor/etc/fstab.default、recovery 用コピー）を turbo の Fstab セクション通りにする。
   - 存在しない場合: rabin 方式（recovery-as-boot、`BOARD_USES_RECOVERY_AS_BOOT`、`virtual_ab_ota.mk`）に戻す。
7. **AB_OTA_PARTITIONS**: GPT 実物と照合して確定する（turbo の10個を上限候補とし、存在しないパーティションは落とす）。
8. **TARGET_RECOVERY_FSTAB**: fstab.qcom を使う（rabin の fstab.default と中身がほぼ同一であることは実測済み）。

### C. AVB

9. BoardConfig に turbo の vbmeta_system 設定一式を移植する（対象 system / system_ext / product、SHA256_RSA2048、testkey、ロールバックインデックス location 1）。rabin の fstab が既に `avb=vbmeta_system` を参照しているため、これは世代に関係なく必要な整合取り。`BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT` は vendor_boot 採用時のみ有効化する。

### D. VINTF

10. turbo の vintf/manifest.xml を採用し、BoardConfig の互換マトリクス指定（qcom-caf common、hardware/xiaomi）を持ち込む。LOS21 世代の hardware/qcom-caf（lineage-21 ブランチ）の FCM と target-level 5 の組み合わせが checkvintf を通るかはビルド時に確認する。

### E. sepolicy

11. turbo の sepolicy/vendor（13ファイル）を移植し、BoardConfig に device/qcom/sepolicy_vndr と libperfmgr sepolicy の include を追加する。LOS21 世代の sepolicy_vndr との型の差（hal_lineage_health 等の世代依存型）で neverallow が出たら都度直す。rabin には sepolicy が無いため、ここは新規構築として扱う。

### F. device.mk と HAL の世代調整（LOS23.2 → 21 へ下げる主戦場）

12. **qcom-caf の世代**: turbo は `hardware/qcom-caf/sm8350/audio` 等、LOS23 世代の qcom-caf 構成を参照している。LOS21（lineage-21 ブランチ）に sm8350 audio が存在するかを確認し、参照先を実在する世代に合わせる。存在しない場合は LOS21 の holi 向け構成がある SoC ツリーから相当品を持ってくる。
13. **AIDL HAL の有無**: device.mk の AIDL 世代パッケージ（boot-service.qti、health-service.qti、fingerprint-service.xiaomi、sensors-service.xiaomi-multihal、power-service.lineage-libperfmgr 等）が LOS21 世代の hardware/qcom-caf / hardware/xiaomi に存在するか確認する。無いものは HIDL 版（rabin の boot@1.2、health@2.1 等）に差し戻す。
14. **FeliCa / NFC の切り分け**: 本プロジェクトでは対象外と決定済み。device.mk の NFC / Secure Element セクションと関連する権限 XML、blobs 側の felica 設定は除外する。ただし `PRODUCT_MODEL := XIG02` の維持は FeliCa 以外のアプリ互換にも効くため、残すかどうかを別途決める（要判断事項）。
15. **lineage.dependencies の作成**: LOS21 用に hardware/xiaomi（lineage-21）と kernel/oneplus/sm4350（UAPI ヘッダ用、lineage-21 対応ブランチ）を指定する。prebuilt カーネルは turbo 23.2 と同じツリー内 prebuilts/ 方式とし、別 repo には分離しない。
16. **API 30 vendor の互換策**: `PRODUCT_SHIPPING_API_LEVEL := 30`、`PRODUCT_ENABLE_UFFD_GC := false`、vndservicemanager の追加は turbo のまま持ち込む。.23 カーネルでも CONFIG_USERFAULTFD が無効かは、当日ダンプから kernel config を抽出して確認する。

### G. その他

17. overlay / audio / configs / power / wifi の各ディレクトリは turbo から移植する。ただし README 注記通り、powerhint.json の値と power_profile.xml は他機種（oneplus/dre）由来の未実測値なので、起動後に実機で検証・調整する前提で使う。
18. rootdir は turbo のもの（init.qcom.rc、init.target.rc、fstab.qcom、charger_fstab.qcom、ueventd.rc、init.recovery.qcom.rc）を採用する。rabin 側の MIUI 固有スクリプト（init.mi.usb.sh、miui.factoryreset.rc 等）は持ち込まない。
19. 軽量・省電力（最優先3本柱のうち2つ）は LOS21 の仕組みの範囲で別途設計する（docs/tuning.md 側の担当。本計画では土台の起動を優先し、turbo 24.0 の mmd / ZRAM writeback 等は持ち込まない）。

---

## 4. リカバリの有無と、ダンプ取得の推奨手段

### 4-1. 既製品リカバリの調査結果

| 候補 | 状態 | 根拠 |
|---|---|---|
| TWRP 公式 | **無し** | twrp.me のデバイス一覧データ（search.json）に iris の項目が無いことを確認 |
| OrangeFox 公式 | **無し** | 公式 API（api.orangefox.download）で codename=iris の検索結果が 0 件であることを確認 |
| GitHub 上の TWRP ツリー（rabin-tech/twrp_xiaomi_iris、Xiaomi-iris-Developments/device_xiaomi_iris の twrp-12.1、twrpdtgen/android_device_xiaomi_iris） | ツリーのみ。**Releases は全て無し**（ビルド済みイメージの配布なし） | 各 repo の Releases ページを確認 |
| SourceForge「redmi-note-10-je-xig02」プロジェクトの **twrp-3.7.0_12-2-iris.zip** | **唯一の既製品**。TWRP 3.7.0（Android 12.1 世代ベース）のインストーラ zip。有志配布（純正 ROM 再パックと同じ配布元） | SourceForge プロジェクトのファイル一覧（RSS）で存在を確認 |

入手先: https://sourceforge.net/projects/redmi-note-10-je-xig02/files/twrp-3.7.0_12-2-iris.zip/download

注意点:
- 配布形態が zip（現行 boot へ TWRP ramdisk を組み込むインストーラ型と推定される）ため、**中に `fastboot boot` 可能な boot.img が同梱されているかは未確認**（今回はダウンロードしていない）。
- この zip の実機動作報告は確認できていない。XDA の XIG02 スレッドでは（他機種用 recovery を試したケースで）タッチが効かないという報告があるが、この iris 用 zip 自体の報告ではない。

### 4-2. ダンプ取得の推奨手段（優先順）

1. **TWRP zip の中身確認 → boot.img があれば `fastboot boot`** で一時起動し、非破壊で全パーティションをダンプする。当日の第一歩は zip の中身確認。
2. boot.img が無い場合: インストーラ zip を現行 boot に適用すると boot が書き換わり、純正 boot のダンプが取れなくなる。書き換える前に、boot 以外のパーティションは書き換え後でも取れるが、boot 自体は取れなくなる点に注意する。代替として、先に LineageOS 21 のビルド環境側で作る Lineage recovery（または TWRP ツリーからの自前ビルド）を用意できるなら、そちらを `fastboot boot` する方が純正状態を壊さない。
3. どの手段でも、ダンプは既知の読み出し異常箇所（product 内 extent [481373, 512]）で止まらないよう、エラー耐性のある読み出し（dd の conv=noerror 等）で行い、失敗ブロックの位置を記録する。
4. 参考: 同じ SourceForge プロジェクトには dsu_install_g15.zip（DSU 導入用）もあるが、これはダンプ用途ではない。

---

## 5. 不明点・未確認事項

- 実機 .23 の GPT 実物: vendor_boot パーティションの有無、dtbo の物理サイズ、各パーティションの実サイズ。アンロック当日に確定する（作業リスト B の分岐条件）。
- .23 純正カーネルの版数（5.4 系のどこか）と CONFIG_USERFAULTFD の有無。当日ダンプ後に確認。
- .23 と .26 の blobs 差分（ファイルの増減）。ダンプ後に proprietary-files.txt と突き合わせて確定する。
- 実機 .23 の fingerprint 文字列（BuildDesc のビルド ID 部分が TKQ1.220905.001 で同一か）。当日 getprop で確認。
- twrp-3.7.0_12-2-iris.zip の中身（boot.img 同梱の有無）と実機動作（タッチ等）。未ダウンロードのため未確認。
- LOS21 世代の hardware/qcom-caf に sm8350 audio や各 AIDL HAL が揃っているか。ビルド環境（lineage-21 のツリー一式）を用意した時点で判明する。
- Seifood の LOS20 ビルドで使われた device tree の実体（監査メモから継続の未確認事項）。
- turbo ツリーは未ビルド・未起動（README 明記）のため、その設定値の正しさ自体が実績に裏付けられていない。移植後に動かない箇所が出る前提で、rabin / LOS20 世代の構成との差分比較ができる状態を保つ。

---

## 6. 出典

- refs/rabin-device: https://github.com/rabin-tech/device_xiaomi_iris
- refs/seifood-vendor: https://github.com/Seifood/vendor_xiaomi_iris-2 （lineage-20）
- refs/turbo-device: https://github.com/turbo-boo/android_device_xiaomi_iris （lineage-23.2）
- refs/turbo-kernel: https://github.com/turbo-boo/android_device_xiaomi_iris-kernel
- TWRP 公式デバイス一覧: https://twrp.me/search.json
- OrangeFox 公式 API: https://api.orangefox.download/v3/devices/?codename=iris
- SourceForge プロジェクト: https://sourceforge.net/projects/redmi-note-10-je-xig02/files/
- 関連メモ: research/device-tree-audit.md、research/ota-install-error.md、research/stock-rom-findings.md
