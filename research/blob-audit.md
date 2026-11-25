# blob 監査（2026-11-26、.23 ダンプ実物との照合）

dump-home のスロットBイメージ（system_b / system_ext_b / product_b / vendor_b / odm_b）を
debugfs で展開し、既存 device tree 2系統の proprietary-files.txt と全件照合した。

## 結果

| ツリー | 総数 | .23 に存在 | 不足 |
|---|---|---|---|
| turbo-device（lineage-23.2） | 2,184 | **2,184（100%）** | 0 |
| rabin-device | 3,105 | 2,996 | 109 |

- turbo の唯一の要確認だった `odm/etc/build_kddi.prop` も odm_b 内に実在を確認済み
- **結論：turbo ツリーの blob 一式は .23 ダンプから全て賄える**。ベースツリーは turbo を本命とする
- ただし turbo の prebuilt カーネルは .26 の 5.4.259 前提。プランBでは boot_b 由来の
  **5.4.233 に差し替え**、モジュールも .23 の vendor_boot/vendor 側と揃えること

## rabin ツリーの不足 109 件の傾向

- 指紋認証まわり（vendor.qti.hardware.fingerprint@1.0、vendor/lib64/hw/fingerprint.fpc.so）
- GNSS（vendor.qti.gnss@1.0〜2.x 系）
- カメラ補助（camera.device@3.5、scve、cvp の adapter-helper 群）
- ADSP の QVR 系 skel ライブラリ（system_ext/lib/rfsa/adsp/libqvr_*、libtracker_6dof_*）
- パネル校正 XML（qdcm_calib_data_xiaomi_K19J_*）→ JP 機のパネルと異なる系統の可能性

→ rabin ツリーは別バリアント（グローバル版等）前提の色が強く、XIG02（JP/KDDI）では turbo を優先する

## 付随して回収したもの

- 純正カーネル設定: research/stock-kernel-5.4.233.config（boot_b の IKCONFIG から抽出、181,579 バイト）
  - CONFIG_LOCALVERSION="-perf"、F2FS/EROFS/OVERLAY_FS は組み込み、モジュール有効
- 各パーティションのファイル総数: vendor 3,536 / system 3,413 / system_ext 1,744 / product 1,585
