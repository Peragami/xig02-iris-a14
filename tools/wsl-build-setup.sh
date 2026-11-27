#!/bin/bash
# XIG02 (iris) LineageOS 21 ビルド用 ノートPC (WSL2) セットアップ
# 想定: Windows 11 + WSL2 + Ubuntu 22.04 / RAM 16GB / Cドライブ空き約300GB
# GCP版 (gcp-build-vm-setup.sh) との違い:
#   - 作業場所は WSL の ext4 内 ($HOME/android/lineage)。/mnt/c 上では絶対にビルドしない
#     （遅い・パーミッションと大文字小文字の扱いで壊れる）
#   - ディスクが tight なので ccache は 25GB に絞り、各フェーズで空き容量を警告する
#   - RAM 16GB 前提: ビルド時の -j は控えめに（手順は docs 側）
# 使い方: フェーズごとに実行する
#   bash wsl-build-setup.sh phase0   # 環境チェック（場所・容量・メモリ）
#   bash wsl-build-setup.sh phase1   # パッケージと repo ツール
#   bash wsl-build-setup.sh phase2   # ソース初期化とローカルマニフェスト配置
#   bash wsl-build-setup.sh phase3   # repo sync（数時間・約150〜200GB）
set -euo pipefail

WORKDIR="${WORKDIR:-$HOME/android/lineage}"

warn_space() {
  local free_gb
  free_gb=$(df -BG --output=avail "$HOME" | tail -1 | tr -dc '0-9')
  echo "空き容量: ${free_gb}GB (WSL の仮想ディスク)"
  if [ "$free_gb" -lt 80 ]; then
    echo "[WARN] 空きが 80GB 未満です。sync やビルドが途中で止まる可能性があります" >&2
  fi
}

phase0() {
  case "$WORKDIR" in
    /mnt/*) echo "[NG] WORKDIR が /mnt 配下です。ext4 内にしてください: $HOME/android/lineage" >&2; exit 1 ;;
  esac
  echo "WORKDIR: $WORKDIR"
  warn_space
  echo "CPU: $(nproc) / MEM:"; free -h | head -2
  echo "--- .wslconfig の推奨 (Windows 側 C:\\Users\\<名前>\\.wslconfig) ---"
  echo "[wsl2]"
  echo "memory=13GB"
  echo "swap=32GB"
  echo "processors=10"
  echo "（設定後は PowerShell で wsl --shutdown してから Ubuntu を開き直す）"
  echo "phase0 done"
}

phase1() {
  sudo apt-get update
  sudo apt-get install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git git-lfs gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev \
    lib32z1-dev libelf-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev \
    libssl-dev libwxgtk3.0-gtk3-dev libxml2 libxml2-utils lzop pngcrush rsync \
    schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3 \
    openjdk-17-jdk android-sdk-platform-tools-common adb fastboot unzip
  mkdir -p "$HOME/bin"
  curl -s https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/repo"
  chmod a+x "$HOME/bin/repo"
  grep -q 'HOME/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  # ccache: ディスク節約のため 25GB（GCP版より小さめ）
  ccache -M 25G || true
  grep -q 'USE_CCACHE' "$HOME/.bashrc" || {
    echo 'export USE_CCACHE=1' >> "$HOME/.bashrc"
    echo 'export CCACHE_EXEC=$(which ccache)' >> "$HOME/.bashrc"
  }
  warn_space
  echo "phase1 done. git config user.name/user.email を設定してから phase2 へ"
}

phase2() {
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"
  # LineageOS 21 (Android 14)
  "$HOME/bin/repo" init -u https://github.com/LineageOS/android.git -b lineage-21.0 --git-lfs
  mkdir -p .repo/local_manifests
  cat > .repo/local_manifests/iris.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- iris device tree: turbo 系統を本命とする（blob 監査で .23 と 100% 一致を確認済み）
       注意: 同梱 prebuilt カーネルは .26 の 5.4.259。プランBでは使わず、
       ダンプの boot_b から抜いた 5.4.233 に差し替えること -->
  <project name="turbo-boo/android_device_xiaomi_iris" path="device/xiaomi/iris"
           remote="github" revision="lineage-23.2" />
  <!-- vendor blobs はダンプから抽出して配置する（research/blob-audit.md 参照） -->
</manifest>
EOF
  echo "phase2 done. phase3 (repo sync) は数時間＋約150〜200GB かかります"
}

phase3() {
  warn_space
  cd "$WORKDIR"
  "$HOME/bin/repo" sync -c -j"$(nproc)" --force-sync --no-clone-bundle --no-tags
  echo "phase3 done (sync complete)"
}

case "${1:-}" in
  phase0|phase1|phase2|phase3) "$1" ;;
  *) echo "usage: $0 phase0|phase1|phase2|phase3" >&2; exit 1 ;;
esac
