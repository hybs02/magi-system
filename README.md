# MAGI SYSTEM

『新世紀エヴァンゲリオン』の MAGI システムを再現した、ブラウザだけで動く合議シミュレータ。
議題を入れると、3体の AI（MELCHIOR・BALTHASAR・CASPER）が別々の LLM エージェントとして推論し、意見表明 → 反論 → 再評価（翻意あり）→ 多数決で議決する。返答は毎回 LLM がその場で生成する（定型文ではない）。

![status](https://img.shields.io/badge/dependencies-none-brightgreen) ![status](https://img.shields.io/badge/build-not%20required-blue) ![status](https://img.shields.io/badge/LLM-Ollama%20%7C%20Gemini-orange)

## 使い方

`index.html` をブラウザで開き、議題を入れて「審議開始」を押す。推論エンジンは次のどちらかが要る。

| エンジン | 向き | 準備 |
| --- | --- | --- |
| LOCAL（[Ollama](https://ollama.com)） | 無料・回数の制限なし・データは端末の外に出ない | Ollama とモデルを入れる（下の「ローカル AI」） |
| EXTERNAL（Google Gemini 無料枠） | PC が無くてもスマホ単体で動く | API キーを貼る（下の「クラウド AI」） |

起動時に LOCAL → EXTERNAL の順で自動検出する。ENGINE CONFIG の「LOCAL があっても EXTERNAL を使う」にチェックを入れると、LOCAL を探さずに EXTERNAL を使う。

| 操作 | キー・ボタン |
| --- | --- |
| 審議開始 | 入力欄で Enter／`Ctrl+Enter`／「審議開始」 |
| 中止 | `Esc`／「中止」（実行中のリクエストごと止める） |
| エンジンを探し直す | 「再検出」 |
| 審議記録をコピー | 審議モニタの「COPY」 |
| ログの最新へ戻る | 「↓ 最新へ」（読み返している間は自動スクロールが止まる） |

### ローカル AI（Ollama）

```bash
# 1. Ollama を入れる  https://ollama.com
# 2. モデルを取る（VRAM 6GB 級ならこれ）
ollama pull qwen3.5:4b
# 3. index.html をブラウザで開く
```

`file://` で直接開く時は、ブラウザから Ollama へつなぐために一度だけ全オリジンを許可する。

```powershell
# Windows。設定後に Ollama を再起動
setx OLLAMA_ORIGINS "*"
```

ローカルサーバー経由（`http://localhost:8000` など）で開くなら設定は要らない。

```bash
python -m http.server 8000   # magi-system フォルダで実行
```

モデルは自動で選ぶ（下の「LOCAL のモデルの選び方」）。決まったモデルを使いたい時は ENGINE CONFIG の「LOCAL: モデル名」に入れる（前方一致。大きな GPU で 12B 以上を使いたい時など）。

Gemma 4 は 12B から、Qwen 3.6 は 27B からで、6GB 級の GPU には載らない。この規模の GPU では Qwen 3.5 の 4B が合う。

### クラウド AI（Gemini・スマホ単体）

1. [Google AI Studio](https://aistudio.google.com/apikey) で無料の API キーを取る
2. 画面下の ENGINE CONFIG を開き、「EXTERNAL: Gemini APIキー」に貼って「保存して再検出」

- キーは端末内（localStorage）にだけ保存し、送り先は Gemini API だけ。
- モデルは使えるものの中から自動で選ぶ（Flash-Lite を優先し、同じ種類なら新しい世代）。
- 無料枠には1日の上限がある。1議題で約9〜12回リクエストする。上限に達するとアプリが知らせる（米国太平洋時間0時＝日本の昼頃にリセット）。

### スマホから使う（PC をサーバーにする）

```bash
python -m http.server 8000      # PC 側で実行
```

スマホのブラウザで `http://<PCのIPアドレス>:8000/index.html` を開く。
同梱の `スマホ用サーバー起動.bat`（Windows）は IP を表示してからサーバーを起動する。
ページを PC の IP で開くと、Ollama の接続先もその IP（ポート 11434）になる。

初回だけ Windows ファイアウォールで許可する（自宅など信頼できるネットワークでだけ）。

```powershell
# 管理者 PowerShell
New-NetFirewallRule -DisplayName "MAGI web 8000" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Profile Private
New-NetFirewallRule -DisplayName "MAGI ollama 11434" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434 -Profile Private
```

Ollama が LAN 側からの接続を受けるには `OLLAMA_HOST` の設定も要るはず（未確認）。

## 3体の人格

| ユニット | 役割 | 判断基準 |
| --- | --- | --- |
| MELCHIOR・1 | 社会性 | 世間の常識・社会的責任・現実的な落としどころ・論理（皮肉とユーモアを交える） |
| BALTHASAR・2 | 純粋性 | 理想・人間の善性への信頼（性善説）・慈愛 |
| CASPER・3 | 利己性 | 自分の損得・快楽・本能的な欲求 |

判断の軸が違うので同じ議題でも意見が割れ、討論のあとで実際に立場を変えることがある。

## 審議の流れ

```
第一段階  意見表明         3体が並行して賛否と根拠を出す
第二段階  討論（最大2巡）   最も対立する相手を名指しで反論。巡ごとに焦点を変え、論点の重複を避ける
第三段階  再評価 → 最終投票  討論を踏まえて翻意してよい。多数決で議決
```

意見が全会一致なら討論は1巡にする。

## 画面

| 部分 | 中身 |
| --- | --- |
| NERV 風 UI | 提訴／決議の帯、3ブロックの色面、走査線、可決＝シアン／否決＝レッドの発光 |
| 審議モニタ | 誰が誰に何を言ったかを、話者の色・タイムスタンプ付きでその場で表示 |
| 進行表示 | 意見表明 → 討論 → 最終投票のステッパー、応答数・経過時間 |
| 決議サマリー | 審議のあと、各機の最終票と要旨・集計・所要時間 |
| エンジン表示 | `LOCAL ▸ qwen3.5:4b (GPU)` のように、使っているモデルと GPU／GPU一部／CPU を出す |
| 議題の履歴 | 入力欄で過去の議題を候補に出す |
| スマホ | レスポンシブ表示・入力欄の自動ズーム防止・押しやすいボタン・画面の高さに合わせたログ |

## LOCAL のモデルの選び方

モデル名の表は持たない。Ollama の `/api/tags` が返すメタ情報（パラメータ数・容量・能力）だけで決めるので、新しい世代を入れれば書き換えなしでそちらを使う。

1. GPU に載る大きさ（6.5GB を目安）を先にする
2. 日本語と役割演技の得手で系統を並べる（Qwen・Gemma → GLM → DeepSeek・Llama・Mistral など → …）
3. 同じ系統なら新しい世代（`qwen3.5` > `qwen3`）
4. 同じ世代ならパラメータが多い方

埋め込み・画像生成・音声認識など会話できないモデルは外す。
選んだあと実際に読み込み、`/api/ps` で GPU に載ったかを確かめる。溢れていれば、載りそうな小さいモデルへ1回だけ切り替える。モデル名を手で指定した時は切り替えず、確かめて表示するだけ。

## LLM の出力を整える処理

| 処理 | 中身 |
| --- | --- |
| JSON の取り出し | 途中で切れた応答・前置き・コードフェンス・二重オブジェクトからも本文を復元する |
| 賛否と本文の一致 | 冒頭の明示的な結論（`可決。`／`否決。`）を先に採る。「可決できるわけじゃない」のような否定形を賛成と取り違えない |
| 出力の掃除 | HTML／Markdown の混入を除き、長すぎる応答は文末で切る |
| 日本語の担保 | 日本語以外の応答を検知したら作り直させる |
| 繰り返しの抑制 | 巡ごとに討論の焦点を変え、反復ペナルティを付ける |
| 思考出力の抑止 | 推論モデル（Qwen3 系など）は `think:false` で抑え、`<think>` が出ても除く |
| レート制限（EXTERNAL） | リクエストを直列にし、429 が出たら間隔を広げる。分あたりの制限は待って回復し、日次上限とは分けて扱う |
| 無料枠のやりくり | 上限はモデルごとなので、1日の上限が大きい Flash-Lite を先に使う。上限に達したら残りの候補モデルへ切り替えて審議を続ける |
| 思考トークン | Gemini 3 系は思考を切れないので、出力枠を厚く取り思考を最小にする。`MAX_TOKENS` で切れたら枠を広げて取り直す |

## 動作環境

- モダンブラウザ（Chrome／Edge／Safari）
- LOCAL を使う時は Ollama と、3GB 程度の VRAM か RAM
- 依存パッケージなし・ビルド不要

## ファイル構成

```
index.html                  本体（HTML/CSS/JS 一体）
manifest.webmanifest        ホーム画面に追加した時の設定
favicon.ico / icon-*.png    アイコン
スマホ用サーバー起動.bat     PC の IP を表示して http.server（ポート 8000）を起動
.claude/launch.json         開発用のプレビュー設定（ポート 8765）
LICENSE                     MIT License
```

## ライセンス／免責

個人が趣味で作った非公式のファンプロジェクト。

『新世紀エヴァンゲリオン』および MAGI システムに関する権利は株式会社カラー等の権利者に帰属する。このリポジトリは権利者と一切関係がなく、商用利用を目的としない。UI は作品の意匠に着想を得た再現で、公式の素材は含まない。

ソースコードは MIT License で利用できる。
