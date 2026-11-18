# ロードマップ

最優先は **安全・軽量・省電力** の3点（README参照）。安全の前提（復旧用ROMとバックアップ）が揃わない工程には進まない。

## Phase 0: ブートローダーアンロック待ち（〜2026-11-25）

- [x] 開発者オプションを有効化
- [x] SIMをRedmiへ移植し、Miアカウントを新規作成
- [x] Mi Unlock status への紐付け成功（2026-11-18）
- [x] iris device tree の精査（2026-11-18）: 源流は rabin-tech/device_xiaomi_iris（LOS19.1世代相当）。Seifood は vendor tree のみ（lineage-20、blobs は V13.0.9.0）。最も新しい turbo-boo のツリーは LOS23.2/24 専用で LOS21 には使えず、部品取り・設計の手本とする。詳細は research/device-tree-audit.md
- [x] LineageOS 21 移植に不足するもののリスト化（同レポートに記載。blobs再抽出、カーネルprebuilt分離、sepolicy新設、VINTF更新、AVB明示設定 等）
- [x] 実機の V14.0.26.0 への OTA 更新は **断念**（2026-11-18 確定）。状態リセット後の完全な初回適用でも product の同一箇所（extent [481373, 512]）の読み出し I/O エラーで失敗し、領域の読み出し異常と判定（research/ota-install-error.md）。初期化も product には効果がないため行わない
  - 代替として **V14.0.23.0 を土台にするプランB** に切り替え済み（Phase 2 参照）
- [x] 復旧用ROMの調査（2026-11-18）: 公式 Fastboot ROM は存在しないことが判明。有志版は最新 V14.0.21.0 で製作者の警告付き。詳細は research/stock-rom-findings.md
- [x] 復旧方針の切り替え: 自前フルダンプを本線とする手順を設計済み（[docs/safety.md](safety.md)、当日の手順は docs/unlock-day.md、ダンプは tools/dump-partitions.bat / .sh）。有志ROMはフル復旧には使わず、切り分け用途に限定する
- [ ] 端末データのバックアップ（アンロックで全消去される）

待ち期間中の条件: Miアカウントをサインアウトしない、端末を初期化しない。

## Phase 1: アンロックと動作棚卸し

- [ ] Mi Unlock Tool で残り時間を確認し、アンロックを実行（当日の手順書： docs/unlock-day.md）
- [ ] 何も焼く前に全パーティションのフルダンプを取る（super、persist、modemst1・2、fsg、boot、dtbo、vbmeta 等。safety.md の必須バックアップ。これが復旧の本線）
- [ ] OTA失敗の既知箇所（product の一部領域）の生読み出しテストをリカバリ経由で行い、dmesg でストレージ側のエラーを確認する
- [ ] 最初の試行は DSU / `fastboot boot` の一時起動で行い、書き込まない状態で確認する
- [ ] 専用ROMを焼く前に、GSI（Android 14）での試し焼きも選択肢として検討
- [ ] 起動 / Wi-Fi / カメラ / 指紋 / モバイル通信（au）/ 音声 / 充電 の動作を棚卸し

## Phase 2: LineageOS 21 専用ビルド

- [ ] 土台は rabin device tree + Seifood vendor（LOS20到達実績あり）とし、turbo-boo ツリーから設定値・構成（blobs リスト、AVB、VINTF、sepolicy 等）を移植する（turbo の .26 前提の値は .23 用に読み替える）
- [ ] カーネルは公式ソース未公開のため、実機 V14.0.23.0 のダンプから取り出した prebuilt（kernel / DTB / DTBO / vendor モジュール）を分離管理する（turbo の iris-kernel 方式を .23 で行う）
- [ ] blobs を実機 V14.0.23.0 のダンプから抽出し、SPL を 2024-04-01 に一致させる
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
