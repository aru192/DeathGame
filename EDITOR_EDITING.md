# Godotエディタ編集ガイド

## ステージを編集する

`scenes/level.tscn`を開き、2Dビューで編集します。

- `Stage/Platforms`: 足場と地面。インスタンスを選び、位置と`size`を変更します。
- `Stage/Hazards`: トゲ、周期トゲ、接近反応槍。`kind`、`size`、`damage`、`period`をInspectorで調整できます。
- `Actors`: プレイヤー、通常敵10体、ボス。敵の`kind`で近接・遠距離・待ち伏せを切り替えられます。
- `Checkpoints`: 中間地点とボス前の霊火。位置と`checkpoint_id`を編集できます。
- `Environment`: CanvasModulateと背景。全体の色調や背景スクリプトを調整できます。

各要素はPackedSceneのインスタンスなので、個別配置を変更しても共通ロジックは壊れません。同種の敵や罠を追加する場合は、既存ノードを複製して名前と位置を変更してください。グループ`enemies`または`hazards`は複製時に維持されます。

## 画面を編集する

- `scenes/main.tscn`: 起動時の全体構成
- `scenes/title_screen.tscn`: タイトル背景、メニューパネル、文章、ボタン
- `scenes/hud.tscn`: HUDロジックのルート

タイトル画面のテキストや位置、サイズ、色は`title_screen.tscn`上のControlノードを直接編集できます。

## キャラクターとゲームバランス

- `resources/player_balance.tres`: 移動速度、加速度、ジャンプ、コヨーテタイム、HP、スタミナ、回避、回復
- `scenes/enemy.tscn`: 通常敵の共通初期値
- `scenes/boss.tscn`: ボス最大HP

プレイヤー・敵・罠・ボスの見た目は`@tool`対応の描画スクリプトなので、各シーンや`level.tscn`でプレビューされます。見た目を変更する場合は対応するスクリプトの`_draw()`を編集してください。

## スクリプト生成のまま残しているもの

攻撃中だけ存在するHitbox、敵弾、着地・ヒットエフェクト、死亡後の再生成、ポーズ内の一時モーダルは、ゲーム状態に応じた一時ノードのためランタイム生成です。恒常的なステージ配置とタイトル画面はすべてシーンファイル側へ移行済みです。
