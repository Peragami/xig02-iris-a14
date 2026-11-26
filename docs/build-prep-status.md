# ビルド準備の状態（2026-11-26、むぜVM側）

GCP ビルド VM の起動を待つ間に、むぜの VM で可能な準備は完了した。

## 済み

- ダンプ（dump-home）の受領と検証: manifest 照合 78/78 一致（research/dump-home-analysis.md）
- 純正カーネル設定の抽出: research/stock-kernel-5.4.233.config
- blob 監査: turbo ツリー 2,184 件が .23 に 100% 存在（research/blob-audit.md）
- **blob 実物のステージング**: むぜVM `~/workspace/xig02-transfer/prep/proprietary/` に
  turbo の一覧どおり 2,184 ファイル（約1.2GB）を配置済み
- **カーネル prebuilt セットのステージング**: 同 `prep/kernel/` に
  - Image（boot_b 由来、5.4.233、43,082,240 バイト）
  - dtb.img（vendor_boot_b 由来、327,507 バイト）
  - modules-vendor（vendor_b の lib/modules、.ko 242 個）
  - modules-ramdisk（vendor ramdisk の 5.4-gki、.ko 42 個＋modules.load 等）
- GCP VM 用セットアップ: tools/gcp-build-vm-setup.sh（phase1〜3）

## VM が立ったらやること

1. phase1〜3 で LineageOS 21 ソースを同期
2. prep/proprietary と prep/kernel を VM へ転送し、device/xiaomi/iris と vendor/xiaomi/iris に配置
3. turbo ツリーの prebuilt カーネル（5.4.259）を 5.4.233 セットに差し替える
4. lunch lineage_iris → 試しビルド

## むぜVMではできないこと（GCP が必要な理由）

- repo sync（約200GB・数時間）と本ビルド（RAM 16GB 以上が現実的なライン。むぜVMは 6GB／1.5コア）
