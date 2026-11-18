# ロードマップ

最優先は **安全・軽量・省電力** の3点（README参照）。安全の前提（復旧用ROMとバックアップ）が揃わない工程には進まない。

## Phase 0: ブートローダーアンロック待ち（〜2026-11-25）

- [x] 開発者オプションを有効化
- [x] SIMをRedmiへ移植し、Miアカウントを新規作成
- [x] Mi Unlock status への紐付け成功（2026-11-18）
- [x] iris device tree の精査（2026-11-18）: 源流は rabin-tech/device_xiaomi_iris（LOS19.1世代相当）。Seifood は vendor tree のみ（lineage-20、blobs は V13.0.9.0）。最も新しい turbo-boo のツリーは LOS23.2/24 専用で LOS21 には使えず、部品取り・設計の手本とする。詳細は research/device-tree-audit.md
- [x] LineageOS 21 移植に不足するもののリスト化（同レポートに記載。blobs再抽出、カーネルprebuilt分離、sepolicy新設、VINTF更新、AVB明示設定 等）
- [ ] 実機をキャリア最新 V14.0.26.0 へ OTA 更新する（blobs再抽出と SPL 2024-08-01 一致の前提。turbo の prebuilt カーネルも .26 純正が前提。更新後も Miアカウントはサインアウトしない）
  - 2026-11-18 時点でインストールエラーにより未達。原因は product パーティション読み出し時の I/O エラーと特定済み（research/ota-install-error.md）。更新状態のリセット→初回適用を試し、ダメならアンロック後に切り分ける
- [x] 復旧用ROMの調査（2026-11-18）: 公式 Fastboot ROM は存在しないことが判明。有志版は最新 V14.0.21.0 で製作者の警告付き。詳細は research/stock-rom-findings.md
- [ ] 復旧方針の切り替え: 自前フルダンプを本線とする手順の設計（[docs/safety.md](safety.md)）。有志ROMの使える範囲の切り分けもここでする（14.0.26.0 へ上げる件は device tree 精査の結果から「上げる」で確定）
- [ ] 端末データのバックアップ（アンロックで全消去される）

待ち期間中の条件: Miアカウントをサインアウトしない、端末を初期化しない。

## Phase 1: アンロックと動作棚卸し

- [ ] Mi Unlock Tool で残り時間を確認し、アンロックを実行
- [ ] 何も焼く前に全パーティションのフルダンプを取る（super、persist、modemst1・2、fsg、boot、dtbo、vbmeta 等。safety.md の必須バックアップ。これが復旧の本線）
- [ ] 最初の試行は DSU / `fastboot boot` の一時起動で行い、書き込まない状態で確認する
- [ ] 専用ROMを焼く前に、GSI（Android 14）での試し焼きも選択肢として検討
- [ ] 起動 / Wi-Fi / カメラ / 指紋 / モバイル通信（au）/ 音声 / 充電 の動作を棚卸し

## Phase 2: LineageOS 21 専用ビルド

- [ ] 土台は rabin device tree + Seifood vendor（LOS20到達実績あり）とし、turbo-boo ツリーから設定値・構成（.26 blobs リスト、AVB、VINTF、sepolicy 等）を移植する
- [ ] カーネルは公式ソース未公開のため、純正 V14.0.26.0 の prebuilt（kernel / DTB / DTBO / vendor モジュール）を分離管理する（turbo の iris-kernel 方式）
- [ ] blobs を V14.0.26.0 から再抽出し、SPL を 2024-08-01 に一致させる
- [ ] 最小限の Google アプリ（Play 3点セット）を組み込み
- [ ] 実機で基本動作を確認

## Phase 3: 軽量化・省電力の最適化

- [ ] low_RAM 設定の適用
- [ ] ZRAM / LMKD の調整
- [ ] 不要なシステムアプリ・常駐サービスの削減
- [ ] 体感セット（アニメ0.5倍、ブラー無効、ランチャー／SystemUI常駐）を適用（[docs/tuning.md](tuning.md)）
- [ ] 省電力セット（Doze強化、スキャンOFF、リフレッシュレート適応型、5G自動切替）を適用（tuning.md）
- [ ] 実機で効果を測る（起動時間、アプリ起動、メモリ使用量、画面オフ中の電池減少）。測れない調整は採用しない

## Phase 4: 上位バージョン実験

- [ ] Android 15 以降の GSI で起動を試す（実験枠。常用は Phase 3 を正とする）
