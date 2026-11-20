# RC Car WebSocket Server

XIAO ESP32-S3上のAtomVMとXRiftを中継する、独立したElixir WebSocketサーバーです。

## 3つのPJの関係

このPJは、PC上で車体側AtomVMとXRiftワールドを中継します。

- [`rc-world`](https://github.com/ymn-t-yamanashi/rc-world)：XRift内の運転席からWASD・カーソル操作を送信します。
- [`ws-server`](https://github.com/ymn-t-yamanashi/rc-ws-server)（このPJ）：`/ws`で接続を受け、メッセージを他のクライアントへ中継します。
- [`atomvm-rc-car`](https://github.com/ymn-t-yamanashi/atomvm-rc-car)：XIAO ESP32-S3上でWSを受信し、GPIO経由でL298Nと左右モーターを制御します。

通信経路は次のとおりです。

```text
XRift rc-world ⇄ WebSocket /ws ⇄ ws-server（PC） ⇄ WebSocket ⇄ atomvm-rc-car（XIAO）
```

基本的な起動順は、`ws-server`、AtomVM、`rc-world`です。ローカルでは`ws://`、Cloud Runでは`wss://`を使用します。

## 起動

```bash
mix deps.get
mix test
mix run --no-halt
```

デフォルトでは`ws://localhost:4000/ws`で待ち受けます。

```bash
PORT=4000 mix run --no-halt
```

起動確認は次のURLで行えます。

```text
http://localhost:4000/health
```

## Docker Compose

Dockerでローカル起動する場合は、次のコマンドを実行します。

```bash
docker compose up --build
```

停止する場合は次のコマンドを実行します。

```bash
docker compose down
```

Docker起動時の接続先は`ws://localhost:4000/ws`です。

## メッセージ

クライアントは接続後にHelloを送信します。

```json
{"type":"hello","role":"device","device_id":"xiao-esp32-s3-01"}
```

モーター操作は次の形式です。

```json
{"type":"motor_set","left":1,"right":1}
```

`left`と`right`は`-1`（後退）、`0`（停止）、`1`（前進）です。

AtomVMは適用後に次の状態を返します。

```json
{"type":"motor_state","left":1,"right":1}
```

受信したメッセージは、送信元以外の接続クライアントへ中継します。

## HTTPS / WSS

開発時は同一LAN内の`ws://`を使用します。Cloud Runでは、Cloud RunがTLSを終端するため、コンテナ内はHTTPで待ち受け、外部からは`wss://`で接続します。

## Google Cloud Run

Artifact Registryへイメージを登録し、Cloud Runへデプロイします。

```bash
PROJECT_ID=<Google CloudのプロジェクトID>
REGION=<Cloud Runのリージョン>
REPOSITORY=<Artifact Registryのリポジトリ名>
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/rc-ws-server:latest"

gcloud builds submit --tag "${IMAGE}"

gcloud run deploy rc-ws-server \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --timeout 3600 \
  --max 1 \
  --concurrency 80 \
  --session-affinity
```

デプロイ後に表示されるサービスURLを使い、XRiftとAtomVMの接続先を次の形式にします。

```text
wss://<Cloud RunのサービスURL>/ws
```

現在のサーバーは接続クライアントをメモリ内で管理しているため、初期運用では`--max 1`を必須にします。Cloud RunのWebSocket接続は最大60分で切断される可能性があるため、クライアント側は再接続できる構成にしてください。
