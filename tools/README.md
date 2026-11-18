# tools

## dump-partitions.bat / dump-partitions.sh

アンロック直後、リカバリを一時起動した状態で全パーティションをダンプするスクリプト。
手順全体は docs/unlock-day.md を参照。

- Windows では `dump-partitions.bat` を **cmd** から実行する（PowerShell の `>` でバイナリを受けると壊れるため、スクリプト内部でも `adb exec-out` を使用）
- bash 環境では `dump-partitions.sh`
- userdata は暗号化済み・巨大なため対象外。それ以外は /dev/block/by-name の全て
- 既知の読み出し異常箇所（research/ota-install-error.md）で止まらないよう `dd conv=noerror,sync` を使用。エラー箇所はゼロ埋めされ、パーティションごとの dd ログ（*.dd.log）に残る
- 出力先に manifest.txt（名前・パーティションサイズ・ファイルサイズ・SHA256）が作られる。ダンプ後はフォルダごと2か所にコピーし、ハッシュ一致を確認すること

### exec-out が使えないリカバリの場合（フォールバック）

ファイルが 0 バイトでスクリプトが停止したら、その旨を報告して判断を仰ぐこと。
代替は「リカバリ内で dd してから adb pull」だが、super が大きいため分割が必要になる。独断で進めない。
