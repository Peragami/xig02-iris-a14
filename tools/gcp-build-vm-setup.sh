#!/bin/bash
# XIG02 (iris) LineageOS 21 ビルド用 GCP VM セットアップ
# 想定: Ubuntu 22.04 LTS / 8 vCPU / 32GB RAM / 250GB disk / asia-northeast1
# 使い方: フェーズごとに実行する（phase3 の repo sync は数時間＋約200GB）
#   bash gcp-build-vm-setup.sh phase1   # パッケージと repo ツール
#   bash gcp-build-vm-setup.sh phase2   # ソース初期化とローカルマニフェスト配置
#   bash gcp-build-vm-setup.sh phase3   # repo sync（長時間・手動実行推奨）
set -euo pipefail

WORKDIR="${WORKDIR:-$HOME/android/lineage}"
DEVICE_REPO_STAGE="${DEVICE_REPO_STAGE:-$HOME/xig02-iris-a14}"

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
  # git の user.name / user.email は本人が自分のものを設定すること（ここでは触らない）
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
  <!-- vendor blobs はダンプから抽出して配置する（extract 手順は research/blob-audit.md） -->
</manifest>
EOF
  echo "phase2 done. phase3 (repo sync) は数時間かかります"
}

phase3() {
  cd "$WORKDIR"
  "$HOME/bin/repo" sync -c -j"$(nproc)" --force-sync --no-clone-bundle --no-tags
  echo "phase3 done (sync complete)"
}

case "${1:-}" in
  phase1|phase2|phase3) "$1" ;;
  *) echo "usage: $0 phase1|phase2|phase3" >&2; exit 1 ;;
esac
