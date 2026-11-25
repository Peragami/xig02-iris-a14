# tools

## dump-partitions.bat / dump-partitions.sh

アンロック直後、リカバリを一時起動した状態で全パーティションをダンプするスクリプト。
手順全体は docs/unlock-day.md を参照。

- Windows では `dump-partitions.bat` を **cmd** から実行する（PowerShell の `>` でバイナリを受けると壊れるため、スクリプト内部でも `adb exec-out` を使用）
- bash 環境では `dump-partitions.sh`
- userdata は暗号化済み・巨大なため対象外。それ以外は /dev/block/by-name の全て
- 既知の読み出し異常箇所（research/ota-install-error.md）で止まらないよう `dd conv=noerror,sync` を使用。エラー箇所はゼロ埋めされ、パーティションごとの dd ログ（*.dd.log）に残る
- 出力先に manifest.txt（名前・パーティションサイズ・ファイルサイズ・SHA256）が作られる。ダンプ後はフォルダごと2か所にコピーし、ハッシュ一致を確認すること

## restore-partitions.bat

ダンプから純正状態へ復元するスクリプト（Windows用）。詳細は docs/restore.md。

- 既定はドライラン：manifest とのサイズ・SHA256 照合と書き込み計画の表示のみで、書き込まない
- 書き込みは引数に `WRITE` を付けた場合のみ。確認入力も必要
- product チェック（iris / XIG02 のどちらか。実機のブートローダーは型番 XIG02 を返す）、super が manifest に無い場合は中断、ダンプ内に読み出しエラー（*.dd.log）がある場合は追加警告＋強い確認入力
- 論理パーティション（system / system_ext / product / vendor / odm）は super に含まれるため個別には焼かない
- **ブートローダーの再ロックは絶対にしない**（公式 Fastboot ROM が無い機種のため）

### exec-out が使えないリカバリの場合（フォールバック）

ファイルが 0 バイトでスクリプトが停止したら、その旨を報告して判断を仰ぐこと。
代替は「リカバリ内で dd してから adb pull」だが、super が大きいため分割が必要になる。独断で進めない。
