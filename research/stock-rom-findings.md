# 純正 Fastboot ROM 確保先の調査結果

- 対象端末: Redmi Note 10 JE（型番 XIG02、au / KDDI 版、コードネーム iris）
- 対象バージョン: MIUI Global 14.0.23.0 (TKRJPKD) / Android 13（実機確認済み、セキュリティパッチ 2024-04-01）
- 調査日: 2026-11-18
- 調査方法: Web 検索とページ本文の確認のみ。ROM 本体はダウンロードしていない

## 結論

1. **Xiaomi 公式の Fastboot ROM（`.tgz`）は存在しない。** 通常の Xiaomi 機種にある `iris_global_images_V14.0.23.0.TKRJPKD_....tgz`（bigota.d.miui.com 等で配布される形式）は、この機種については公開されていない。理由は構造的で、この機種のアップデートは MIUI のアップデータではなく **Google 仕様のアップデータ＋キャリア（KDDI）配信**になっており、Xiaomi の ROM 配布サーバー（c.mi.com / bigota）にファイルが置かれていないため。
2. **対象バージョン V14.0.23.0.TKRJPKD について公式に存在するのは、キャリア OTA のみ。** UQ mobile 公式告知（2024-04-25 配信開始、約 150MB の差分アップデート）で存在が確認できるだけで、単体ファイルの公開 URL はない。**フル Recovery ROM（`.zip`）の公開も確認できなかった**（「Recovery 版しか無い」のではなく、フル ROM 自体が公式には出ていない、が正確）。
3. **Fastboot で焼ける形式のものは有志製作品のみ実在する。** 最も整備されているのは Re*Index（ot_inc）氏が SourceForge で配布する Fastboot ROM で、MIUI 14 系の最新は **V14.0.21.0.TKRJPKD** まで。**V14.0.23.0 の有志 Fastboot ROM も見つからなかった。**
4. 1 つ前の **V14.0.22.0** については、別の有志（t-afro 氏）の SourceForge プロジェクトに `XIG02_global_images_V14.0.22.0_ota.7z`（3.2GB）がある。ただし名称に `_ota` と付く再パック品とみられ、そのまま Fastboot で焼けるかは未確認。
5. **安全面の重要注意:** Re*Index 氏自身が一覧ページで「v14.0.4.0 以降のパーティションサイズ変更」「v14.0.4.0 以降の Fastboot ROM で文鎮化の報告あり、boot.img の使用のみに絞ることを推奨」と明記している。有志 Fastboot ROM は「純正復旧の保険」として無条件には扱えない。

### バージョン表記の読み方（裏付け）

- 先頭の `T` = Android 13（Tiramisu）。`V14.0.23.0.TKRJPKD` の表記と一致する
- `JP` = Japan、`KD` = KDDI を指すとされる（XDA フォーラムの解説、および日本語ブログ「ROM焼き試験場」の `JPKD = Japan / KDDI` 系の解説）
- 索引サイト（HyperOS Updates 等）ではこのリージョンを "Japan Global" と表記しているが、実体は JP / KDDI 向けである

## ファイル情報表

### A. 対象バージョン（公式）

| 項目 | 内容 |
|---|---|
| バージョン | V14.0.23.0.TKRJPKD（ビルド番号表記: 14.0.23.0 (TKRJPKD)） |
| 形式 | キャリア OTA（端末への自動配信のみ。単体ファイルの公開なし） |
| Fastboot 版 (.tgz) | **なし（公式には存在しない）** |
| Recovery 版フル ROM (.zip) | **公開を確認できず** |
| ファイルサイズ | 約 150MB（OTA 差分、UQ mobile 公式告知） |
| Android バージョン | 13（Android 13 適用済み端末向けのセキュリティ更新） |
| セキュリティパッチ | 2024 年 4 月（実機表示 2024-04-01 と一致） |
| 配信開始日 | 2024-04-25 |
| MD5 / SHA | 公開なし |
| リージョン表記 | JP（KDDI 向け） |

### B. 有志 Fastboot ROM（最有力の確保先、Re*Index 製）

| 項目 | 内容 |
|---|---|
| ファイル名 | `Xiaomi_Iris_XIG02_MIUI_V14.0.21.0_TKRJPKD.7z` |
| バージョン | V14.0.21.0.TKRJPKD（対象の 14.0.23.0 より 2 つ前） |
| 形式 | Fastboot ROM（有志が OTA / ダンプから再構成したもの。.tgz ではなく .7z） |
| Android バージョン | 13 |
| ファイルサイズ | **未確認**（SourceForge のファイルページ取得がタイムアウトし、サイズを取得できなかった） |
| MD5 / SHA | **未確認**（同上） |
| 配布元 | SourceForge プロジェクト `redmi-note-10-je-rom`（製作者 Re*Index / reindex） |
| 注意 | 製作者自身が v14.0.4.0 以降版について文鎮化報告と利用制限の推奨を出している（本文参照） |

同プロジェクトで確認できた他の MIUI 14 系: v14.0.4.0 / v14.0.9.0 / v14.0.12.0（いずれも TKRJPKD）。MIUI 13 系は v13.0.10.0 まで、MIUI 12.5 系は v12.5.12.0 がある。

### C. 有志パッケージ（t-afro 氏、V14.0.22.0）

| 項目 | 内容 |
|---|---|
| ファイル名 | `XIG02_global_images_V14.0.22.0_ota.7z` |
| バージョン | V14.0.22.0（対象の 1 つ前。キャリア配信は 2024-03-05 開始、約 110MB、パッチ 2024 年 2 月） |
| ファイルサイズ | 3.2 GB（SourceForge ファイル一覧の表示で確認） |
| 更新日 | 2024-03-25 |
| 形式の中身 | **未確認**（`_ota` 命名の再パック品。Fastboot でそのまま焼けるかは未検証） |
| MD5 / SHA | 未確認 |
| 配布元 | SourceForge プロジェクト `redmi-note-10-je-xig02`（t-afro 氏） |

同プロジェクトには他に `XIG02_global_images_V14.0.4_ota.7z`（3.2GB）、`XIG02_global_images_V13.0.10.0_ota.7z`（2.7GB）、`XIG02_OTA_DownloadUrl.txt`（735 Bytes）などがある。

### D. 参考: 形式・命名が確認できた旧バージョンの有志品

| ファイル名 | バージョン / Android | 備考 |
|---|---|---|
| `Xiaomi_Iris_XIG02_MIUI_V13.0.9.0_SKRJPKD.rar` | V13.0.9.0.SKRJPKD / Android 12 | Re*Index 製 Fastboot ROM。ダウンロード URL を確認済み（下記） |
| `xiaomi-iris-XIG02-MIUI-V12.5.12.0.RKRJPKD-ota-with-repacked-super.7z` | V12.5.12.0.RKRJPKD / Android 11 | ぬいるぽいんた氏の unbrick 用 Fastboot ROM（note 記事で配布）。OTA が受けられなくなる既知の問題ありと本人明記 |

### E. 索引サイトでの iris の扱い

| サイト | iris の最新として扱う版 | 備考 |
|---|---|---|
| HyperOS Updates (hyperosupdates.com) | V14.0.21.0.TKRJPKD | "Japan Global" 表記。Fastboot / Recovery の案内文は他機種共通の定型文で、実ファイルへの直接リンク（bigota 等）はページ本文から確認できなかった |
| MobileOS Updates (mobileosupdates.com) | V14.0.21.0.TKRJPKD | 同上 |
| miuirom.org | **掲載なし** | 日本リージョン一覧（JP index）に Redmi Note 10 JE 自体が載っていない（2026-11-18 確認時点） |
| XiaomiFirmwareUpdater (xiaomifirmwareupdater.com) | 直接の iris ページを確認できず | FAQ で「全ダウンロードリンクは MIUI サーバー直リンク」と説明する方式のため、bigota に無い本機種は実質扱われていないとみられる |

## 入手元 URL 一覧

すべて 2026-11-18 に実際に取得・確認できた URL のみ。ROM 本体はダウンロードしていない。

### 公式（キャリア）

- UQ mobile 公式「Redmi Note 10 JE アップデート情報」（2024-04-25、ビルド 14.0.23.0 (TKRJPKD)、約 150MB、パッチ 2024 年 4 月）
  https://www.uqwimax.jp/information/202404251.html
- UQ mobile 公式（2024-03-05、ビルド 14.0.22.0 (TKRJPKD)）
  https://www.uqwimax.jp/information/202403053.html
- au 公式「Redmi Note 10 JE (XIG02) アップデート情報」（2024-09-10、ビルド 14.0.26.0 (TKRJPKD)、パッチ 2024 年 8 月。キャリア最新は 14.0.23 より先があることの確認用）
  https://www.au.com/information/notice_mobile/update/update-20240910-04/

### 有志 Fastboot ROM（最有力の確保先）

- Re*Index 配布一覧「Xiaomi | Re*Index.Lab」（Redmi Note 10 JE (XIG02) の Fastboot ROM 一覧と警告文）
  https://reindex-ot.github.io/xiaomi/
- SourceForge プロジェクト「Redmi Note 10 JE (Iris) Fastboot ROM」（Re*Index）
  https://sourceforge.net/projects/redmi-note-10-je-rom/
- 同プロジェクト FastbootROM フォルダ
  https://sourceforge.net/projects/redmi-note-10-je-rom/files/FastbootROM/
- 同 V14.0.21.0 のダウンロード URL（ファイル名の確認元。ダウンロードはしていない）
  https://sourceforge.net/projects/redmi-note-10-je-rom/files/FastbootROM/Xiaomi_Iris_XIG02_MIUI_V14.0.21.0_TKRJPKD.7z/download
- 同 V13.0.9.0 のダウンロード URL（命名規則の確認用）
  https://sourceforge.net/projects/redmi-note-10-je-rom/files/FastbootROM/Xiaomi_Iris_XIG02_MIUI_V13.0.9.0_SKRJPKD.rar/download
- SourceForge プロジェクト「Redmi Note 10 JE (XIG02)」（t-afro、V14.0.22.0_ota.7z 等）
  https://sourceforge.net/projects/redmi-note-10-je-xig02/files/

### 索引・データベース

- HyperOS Updates: Xiaomi Redmi Note 10 JE (iris)
  https://hyperosupdates.com/hyperos/iris
- MobileOS Updates: V14.0.21.0.TKRJPKD ページ
  https://mobileosupdates.com/hyperos/iris/version/V14.0.21.0.TKRJPKD
- miuirom.org 日本リージョン一覧（iris の掲載がないことの確認用）
  https://miuirom.org/updates/japan
- PhoneDB: Xiaomi Redmi Note 10 JE XIG02 TD-LTE JP 64GB (Xiaomi Iris) 詳細スペック
  https://phonedb.net/index.php?m=Device&id=18762&c=xiaomi_redmi_note_10_je_xig02_td-lte_jp_64gb__xiaomi_iris&d=detailed_specs

### 日本語の解説記事

- Re*Index の note マガジン「Xiaomi Redmi Note 10 JE まとめ」（Fastboot ROM 中心）
  https://note.com/reindex/m/m2682ab3cab51/rss
- ぬいるぽいんた「Soft-brick した Xiaomi Redmi Note 10 JE XIG02 を unbrick した話」
  https://note.com/nuilpointer/n/n8edba9a7bc49
- XDA Forums「How to Install TWRP on Redmi Note 10JE」（公式 ROM が無いこと、TKRJPKD の読み方の書き込み）
  https://xdaforums.com/t/how-to-install-twrp-on-redmi-note-10je.4682549/post-89622416

## 出典と裏付け

- **コードネーム iris = XIG02 であること**: PhoneDB の端末ページ（Model: Redmi Note 10 JE XIG02 TD-LTE JP 64GB、Codename: Xiaomi Iris、Mobile Operator: KDDI Corporation / UQ Communications）。HyperOS Updates / MobileOS Updates の iris ページ、Re*Index 一覧の見出し「Redmi Note 10 JE (XIG02)」も一致。
- **公式 Fastboot ROM が無いこと**: XDA の書き込み「the Xiaomi Redmi Note 10JE ROM is not available from Xiaomi officially, only those released by volunteers」。ぬいるぽいんた氏の記事「Note10JE の ROM は c.mi.com に落ちてない」。Re*Index 氏の記事「アップデート画面が Google 仕様になっているので ROM のファイルを MIUI 上でダウンロードする事ができない、海外で ROM を配布しているサイトすらなく知らない子な扱い」。miuirom.org の JP 一覧に本機種の掲載がないことも傍証。
- **V14.0.23.0 の公式存在形態**: UQ mobile 公式告知（2024-04-25、約 150MB、約 20 分、パッチ 2024 年 4 月、完了後ビルド 14.0.23.0 (TKRJPKD)）。前後の版も同形式: 14.0.22.0 は 2024-03-05 に約 110MB、14.0.20.0 は 2023-10-31 に約 320MB（マイナビニュースの au 発表まとめ）で、いずれも小型の差分 OTA。
- **有志 Fastboot ROM の最新版と警告**: Re*Index 一覧ページ（https://reindex-ot.github.io/xiaomi/）に v14.0.21.0 (TKRJPKD) までの一覧と、「v14.0.4.0 以降からパーティションのサイズが変わっている」「v14.0.4.0 以降の Fastboot ROM で文鎮化したという報告があった。boot.img の使用のみに絞る事を推奨」の警告文を確認。
- **V14.0.22.0_ota.7z の存在とサイズ**: SourceForge プロジェクト `redmi-note-10-je-xig02` のファイル一覧（ファイル名、3.2GB、2024-03-25 の表示）。

## 未確認事項

- **V14.0.23.0 の OTA ファイル自体の直リンク**: キャリア OTA の実ファイル（payload.bin を含む zip と推定）の公開 URL は見つからなかった。t-afro 氏のプロジェクトにある `XIG02_OTA_DownloadUrl.txt`（735 Bytes）が OTA URL の記録である可能性はあるが、中身は未確認（ダウンロードしていないため）。
- **Re*Index 製 V14.0.21.0 の正確なファイルサイズと MD5/SHA**: SourceForge の該当ファイルページ取得がタイムアウトし、取得できなかった。ダウンロード時に SourceForge 側表示で確認が必要。
- **t-afro 製 V14.0.22.0_ota.7z の中身**: flash バッチを含む Fastboot 焼き可能な構成かどうか、super.img の再パック方式、OTA 可否は未確認。
- **ダウングレード可否**: 実機 14.0.23.0 から有志 ROM の 14.0.21.0 / 14.0.22.0 へ戻すことが anti-rollback に抵触しないかは未確認。XDA の書き込みでは実機の `anti: 1` / `rollback_ver: 1` が報告されている。Re*Index 氏の note には MIUI 14.0.4.0 から MIUI 13 へのダウングレード確認済みという記述があるが、14.0.23 からの検証ではない。
- **実機はキャリア最新ではない**: キャリア最新は 14.0.26.0（2024-09-10、パッチ 2024 年 8 月）。実機の 14.0.23.0 を「最終版」とみなすかどうかは別途判断が要る。
- **Xiaomi 公式 CDN（bigota.d.miui.com / miui.com）上の iris 向けファイル**: 本調査の検索・索引確認の範囲では 1 件も確認できなかった。ただし CDN 上の未索引ファイルの有無までは保証できない。

## 次の一手（提案）

- 「純正 Fastboot ROM を PC に確保してから焼く」という従来計画は、この機種では公式 .tgz が無いためそのままでは成立しない。代替案の検討が必要:
  1. Re*Index 製 V14.0.21.0 を確保候補としつつ、製作者の警告（boot.img 限定推奨）を前提に、復旧手段として使える範囲を先に切り分ける
  2. t-afro 製 V14.0.22.0_ota.7z の中身を確認し、Fastboot 復旧に使えるか評価する
  3. 焼き込み前に実機（14.0.23.0）のパーティションをダンプして自前の復旧イメージを作る方法を本線に据える
