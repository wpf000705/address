#!/usr/bin/env sh
set -eu

APP_NAME="create-address"
REPO_URL="${REPO_URL:-https://github.com/wpf000705/address.git}"
APP_DIR="${APP_DIR:-$HOME/${APP_NAME}}"
PORT="${PORT:-3000}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is required. Please install $1 first."
    exit 1
  fi
}

need_cmd git
need_cmd node
need_cmd npm

node_major="$(node -p "Number(process.versions.node.split('.')[0])")"
if [ "$node_major" -lt 20 ]; then
  echo "Node.js 20+ is required. Current version: $(node -v)"
  exit 1
fi

if [ -d "$APP_DIR/.git" ]; then
  echo "Updating existing app in $APP_DIR"
  git -C "$APP_DIR" pull --ff-only
else
  echo "Cloning app into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"
npm ci

echo
echo "Install complete."
echo "Start the app with:"
echo "  cd $APP_DIR"
echo "  PORT=$PORT npm start"
echo
echo "Then open:"
echo "  http://localhost:$PORT"
