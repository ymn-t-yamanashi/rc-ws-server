# RC Car WebSocket Server

XIAO ESP32-S3上のAtomVMとXRiftを中継する、独立したElixir WebSocketサーバーです。

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

開発時は同一LAN内の`ws://`を使用します。公開XRiftから接続する場合は、Caddy等のTLS終端を前段に置き、XRiftからは`wss://`で接続してください。AtomVMの初期実装はLAN内の`ws://`接続を対象にします。
