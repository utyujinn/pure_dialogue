{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [
    python311
    uv
    ffmpeg
    cmake
    pkg-config
  ];

  shellHook = ''
    # ctranslate2 (faster-whisper) と PyTorch が必要とする native libs
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"

    # uv に nix 提供の Python 3.11 を使わせる（3.14 では wheel が少なくビルドが壊れる）
    export UV_PYTHON="${pkgs.python311}/bin/python3"
    export UV_PYTHON_PREFERENCE="only-system"

    # Windows 側の Ollama (Tailscale IP を指定)
    # 例: export OLLAMA_URL="http://100.x.x.x:11434"
    if [ -z "$OLLAMA_URL" ]; then
      echo "⚠️  OLLAMA_URL が未設定です:"
      echo "   export OLLAMA_URL=\"http://<tailscale-ip>:11434\""
    fi

    # VoiceVox (Windows 側で起動している場合)
    # 例: export VOICEVOX_URL="http://100.x.x.x:50021"
    # export VOICEVOX_SPEAKER=1
    if [ -z "$VOICEVOX_URL" ]; then
      echo "ℹ️  VOICEVOX_URL 未設定 (VoiceVox を使う場合は設定してください)"
    fi

    echo ""
    echo "=== セットアップ手順 ==="
    echo "1. Irodori-TTS をクローン:"
    echo "   git clone https://github.com/Aratako/Irodori-TTS"
    echo ""
    echo "2. 依存パッケージをインストール:"
    echo "   uv sync"
    echo ""
    echo "3. VRM ファイルを配置:"
    echo "   assets/model.vrm"
    echo ""
    echo "4. サーバー起動:"
    echo "   uv run uvicorn backend.main:app --host 0.0.0.0 --port 8000"
    echo ""
  '';
}
