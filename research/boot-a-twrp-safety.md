# boot_a への TWRP フラッシュ＋スロット切替の文鎮化リスク調査（2026-11-25）

## 背景

- 実機の abl は `fastboot boot` 未対応（Booting: FAILED remote: 'unknown command'、端末が正常な状態で再現確認済み）。TWRP の一時起動は不可能
- 代替案: 使っていない a スロットの boot にだけ TWRP を書き、`fastboot --set-active=a` で起動して全パーティションダンプを取る。現行 b（純正 V14.0.23.0）は無傷で残す
- 本書はこの方法で文鎮化しないかを調査した記録

## 結論

**文鎮化しない。** 書き込み対象は boot_a のみで、ブートローダー本体（xbl / abl）には一切触れない。したがって最悪の場合でも fastboot（音量下＋電源）には常に入れ、`fastboot --set-active=b` で純正に戻れる。前進できないリスク（TWRP が a で起動しない等）は残るが、後退不能になる経路は無い。

## 根拠

### 1. スロット制御の仕様（AOSP 公式）

出典: source.android.com「Implement OTA updates」「Implement A/B updates」

- `fastboot set_active`（boot control HAL の setActiveBootSlot）は対象スロットの **slot-unbootable と slot-successful をクリアし、retry count をリセットする**。slot-unbootable を解除する唯一の方法と明記されている → 現在 unbootable:yes の a も、set-active で起動試行対象になる
- ブートローダーは unbootable なスロットを起動しない。現行スロットが successful でなく retry-count が 0 になったら、そのスロットを unbootable にして、**unbootable でなく successful な別スロットを選ぶ** → a の TWRP が起動失敗を繰り返しても、successful:yes の b へ自動フォールバックする設計
- どちらのスロットも使えない場合はリカバリ／エラー画面に行く（文鎮ではなく、fastboot 到達性は abl が無傷な限り残る）

### 2. この実機での改変 boot 起動実績

- XIG02 実機オーナーの記録（ミ田ろぐ／ROM焼き試験場、2021）: Magisk パッチ済み boot.img を fastboot で boot に Flash し、MIUI が root 化状態で正常起動した。**アンロック済み本機では改変 boot イメージが AVB に阻まれず起動する**ことの実証
- 同記録では DSU＋root シェルから `dd if=/dev/block/by-name/boot_a` 等でパーティションを抜き出す手法も使われており、この機種での dd ダンプ自体がコミュニティの実績ある手順

### 3. 触れないもの（絶対ルールとの整合）

- xbl / abl / vbmeta / boot_b には書き込まない。再ロックもしない（safety.md の絶対ルール1・5に抵触しない）
- vbmeta の --disable-verity 等の追加書き込みもしない（アンロック済みでは不要）

## 残るリスク（文鎮化ではなく「進めない」リスク）

1. **TWRP が a で起動しない可能性**: vendor_boot_a は .26 OTA 失敗時の部分書き込み（または旧版）の可能性があり、Android 12 ベースの TWRP と組み合わせが合わないと起動失敗しうる。その場合は自動フォールバック or 手動 set-active=b で復帰
2. **タッチが効かない可能性**: XDA の XIG02 スレッドで他機種用 recovery のタッチ不可報告はあるが、この iris 用ビルド自体の報告ではない。ダンプは adb 駆動（dump-partitions.bat）なので、TWRP が adb 応答すればタッチ不要で進められる。最悪は USB-OTG マウス
3. **上書きで失われるもの**: 現在の boot_a の中身（上書き後は戻せない）。ただし a は既に unbootable マーク付きで .26 OTA の部分書き込み状態と推定され、純正復元の資産としての価値は低い。復元に必須なのは b 側一式＋単独パーティションで、それらはダンプで無傷のまま取得する
4. **フラッシュ中の USB 切断**: boot_a が壊れてもフォールバック経路は同じ。再フラッシュ可能

## フォールバック手順（実施時に手元に置く）

1. 音量下＋電源で fastboot に入る
2. `fastboot --set-active=b`
3. `fastboot reboot` → 純正 V14.0.23.0 が起動する

## 代替ルート（TWRP 方式が全滅した場合）

- DSU（同じ SourceForge プロジェクトに dsu_install_g15.zip がある）＋ root 可能な GSI から dd で抜き出す方式（上記ブログの実績あり）
- LineageOS 21 ビルド時に作る Lineage recovery を boot_a に書く方式（TWRP と同じ枠組み）
