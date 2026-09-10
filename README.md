# map_postal (FiveM Postal Waypoint & 3D GPS Route)

FiveMサーバー向けの軽量スタンドアロンスクリプトです。  
指定した番地（Postal Code）へのマップピン設定と、道路上への **3Dネオン導線（In-World GPS）** のリアルタイム投影を同時に行います。

---

## 🌟 主な特徴

- **スタンドアローン設計**: ESX、QBCore、vRPなどのフレームワークを問わず動作します。
- **3D導線プロジェクション**: ミニマップの紫ルートと完全に同期した滑らかなナビゲーションラインを道路上に描画します（テクスチャファイル追加不要）。
- **自在な切り替え**: `/route true` / `/route false` で道路上の導線表示をいつでも切り替え可能。
- **プレイヤー設定の自動保存**: プレイヤーが切り替えた導線設定（表示/非表示）はサーバー再接続後も自動的に維持されます。
- **高パフォーマンス**: ピンが刺さっていないときは描画ループを完全に停止し、サーバー・クライアント負荷を最小化します。

---

## 📸 機能紹介

- `/map 8054` のようにコマンドを入力すると、該当する番地にルートピンが設定され、道路上に光るガイドラインが出現します。
- `/map` のみを入力すると、設定されたピンと道路上の導線をワンタッチで解除します。

---

## 📁 フォルダ構成

```text
map_postal/
├── fxmanifest.lua
├── client.lua
└── postals.json
```
## 🚀 導入方法
- 1．このリポジトリをダウンロード（または git clone）します。
- 2．フォルダ名を map_postal に変更し、FiveMサーバーの resources/ フォルダ配下に配置します。
- 3．server.cfg に以下の起動コマンドを追記します。

```text
ensure map_postal
```
- 4．サーバーを起動、またはコンソールで refresh → start map_postal を実行します。

- ※注意: 番地テクスチャをマップに表示させるには、別途 [Postal Code Map & Minimap](https://forum.cfx.re/t/release-postal-code-map-minimap-new-improved-v1-3/147458) などのマップテクスチャMODが必要です。

## 🎮 コマンド一覧
コマンド	説明
- /map [番地]	指定した番地にルートピンを刺し、道路上に導線を表示します（例: /map 101）
- /map	現在設定されているルートピンと導線を削除します
- /route	道路上の3D導線の表示 / 非表示を交互に切り替えます
- /route true	道路上の3D導線を有効にします
- /route false	道路上の3D導線を無効（非表示）にします

## ⚙️ カスタマイズ (client.lua)
- client.lua の先頭にある Config テーブルから、色や太さ、デフォルトの挙動を簡単に調整できます。
```text
local Config = {
    DefaultEnableRoute = true,  -- デフォルトで導線を表示するか (true / false)
    SavePreference     = true,  -- プレイヤーごとの設定変更を記憶するか

    -- 導線の見た目
    Color              = { r = 160, g = 32, b = 240, a = 180 }, -- カラー (RGBA)
    RibbonWidth        = 1.0,   -- ラインの横幅（メートル）
    RenderDistance     = 250.0, -- 先の道路を描画する距離（メートル）
    SampleStep         = 4.0,   -- 線のサンプリング間隔
}
```

## 📜 クレジット & 謝辞
- Postal Coordinates Data: [DevBlocky/nearest-postal](https://github.com/DevBlocky/nearest-postal) (MIT License)
