# xig02-iris-a14

Lightweight LineageOS 21 (Android 14) for Redmi Note 10 JE (XIG02 / iris)

Redmi Note 10 JE（型番 XIG02、au版、コードネーム iris）専用の、軽量で端末に最適化した Android 14 カスタムROMプロジェクト。

## 対象端末

| 項目 | 内容 |
|---|---|
| 機種 | Redmi Note 10 JE |
| 型番 | XIG02（au版、日本市場専用） |
| コードネーム | iris |
| SoC | Qualcomm Snapdragon 480 5G |
| RAM / ROM | 4GB / 64GB |
| 公式最終版 | MIUI Global 14.0.23.0 (TKRJPKD) / Android 13 |

詳しくは [docs/device.md](docs/device.md) を参照。

## 方針（仕様 v1）

- ベース: LineageOS 21（Android 14）、iris 専用最適化
- Googleアプリは最小限: Play開発者サービス + Playストア + Googleサービスフレームワークの3点のみ
  （Gmail / Maps / YouTube / Chrome は入れない。必要なら後からPlayで入れる）
- 軽量化は段階的に行う
  1. まず素の状態で起動・Wi-Fi・カメラ・指紋・モバイル通信を確認
  2. その後に low_RAM 設定、ZRAM / LMKD 調整、不要なシステムアプリ・常駐サービスの削減
- FeliCa / おサイフケータイは割り切って対象外とする（カスタムROMでは動かない可能性が高い。eSIMも同様）

## 現在のステータス

- 2026-11-18: Mi Unlock status への紐付け成功（「正常に追加されました」）
- ブートローダーアンロック解禁目安: 2026-11-25 11:09頃（168時間待ちの場合。正確な残り時間は Mi Unlock Tool の表示で確認）
- アンロック待ちの間に、device tree の精査と不足分のリスト化を進める

進め方は [docs/roadmap.md](docs/roadmap.md)、アンロック手順は [docs/unlock.md](docs/unlock.md) を参照。

## 注意

- ブートローダーのアンロックで端末のデータは全て消去される。必ず事前にバックアップすること
- カスタムROMでは Play ストアで「デバイス未認定」と表示される可能性があり、銀行系など一部アプリが使えないことがある
- このリポジトリにはコードと設定だけを置く。vendor blobs、純正ROMイメージ、ビルド成果物の zip / img は含めない（`.gitignore` で除外済み）

## ライセンス

未定（Android / LineageOS の慣例に合わせて後日決定する）
