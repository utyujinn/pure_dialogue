# phone

TCP を使ったシンプルな音声通話ツールです。  
一方が待ち受け、もう一方が IP を指定して接続します。音声の入出力には libsox を使用しています。

## ディレクトリ構成

```
phone/
├── src/        ソースコード (.c, .o)
├── include/    ヘッダファイル (.h)
├── lib/        静的ライブラリ (libphone.a)
├── bin/        実行ファイル (phone)
├── Makefile
├── shell.nix   NixOS 用環境
└── call.sh     起動スクリプト
```

## 環境構築

### Debian / Ubuntu

必要なパッケージをインストールします。

```sh
sudo apt install gcc make pkg-config libsox-dev sox
```

ビルドします。

```sh
make
```

### NixOS

`shell.nix` に必要な依存関係が記述されています。

```sh
nix-shell
make
```

`nix-shell` を抜けると環境は元に戻ります。再ビルドする際も同様に `nix-shell` に入ってから `make` を実行してください。

## 使い方

### 待ち受け側

```sh
./call.sh server [port]
```

ポートのデフォルトは `50000` です。

### 発信側

```sh
./call.sh call <ip> [port]
```

例:

```sh
./call.sh call 192.168.1.10
./call.sh call 192.168.1.10 50001
```

### 直接実行

`call.sh` を介さずにバイナリを直接使うこともできます。

```sh
./bin/phone <port>           # 待ち受け
./bin/phone <ip> <port>      # 発信
```

## オーディオドライバ

デフォルトは ALSA (`alsa`) です。PulseAudio や PipeWire (pulse 互換) を使う場合は以下のようにビルドします。

```sh
make CFLAGS+="-DAUDIO_DRIVER=pulse"
```

macOS では自動的に `coreaudio` が使われます。

## クリーン

```sh
make clean
```
