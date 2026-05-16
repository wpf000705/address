#!/usr/bin/env sh
set -eu

APP_NAME="create-address"
REPO_URL="${REPO_URL:-https://github.com/wpf000705/address.git}"
APP_DIR="${APP_DIR:-$HOME/${APP_NAME}}"
PORT="${PORT:-3000}"

log() {
  printf '%s\n' "$1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    log "sudo is required to install missing system packages."
    exit 1
  fi
}

is_debian_like() {
  has_cmd apt-get
}

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

install_git() {
  if has_cmd git; then
    return
  fi

  log "git is missing. Installing git..."

  if is_debian_like; then
    run_as_root apt-get update
    run_as_root apt-get install -y git ca-certificates curl
  elif is_macos && has_cmd brew; then
    brew install git
  else
    log "Could not install git automatically. Please install git first, then run this script again."
    exit 1
  fi
}

node_major_version() {
  if ! has_cmd node; then
    echo 0
    return
  fi
  node -p "Number(process.versions.node.split('.')[0])"
}

install_node20() {
  current_major="$(node_major_version)"
  if [ "$current_major" -ge 20 ] && has_cmd npm; then
    return
  fi

  log "Node.js 20+ and npm are required. Installing Node.js 20..."

  if is_debian_like; then
    run_as_root apt-get update
    run_as_root apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://deb.nodesource.com/setup_20.x | run_as_root bash -
    run_as_root apt-get install -y nodejs
  elif is_macos && has_cmd brew; then
    brew install node@20 || brew install node
    if ! has_cmd node && [ -x "/opt/homebrew/opt/node@20/bin/node" ]; then
      export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
    fi
    if ! has_cmd node && [ -x "/usr/local/opt/node@20/bin/node" ]; then
      export PATH="/usr/local/opt/node@20/bin:$PATH"
    fi
  else
    log "Could not install Node.js automatically. Please install Node.js 20+ first, then run this script again."
    exit 1
  fi

  current_major="$(node_major_version)"
  if [ "$current_major" -lt 20 ] || ! has_cmd npm; then
    log "Node.js 20+ installation did not complete correctly. Current node: $(node -v 2>/dev/null || echo missing)"
    exit 1
  fi
}

install_git
install_node20

if [ -d "$APP_DIR/.git" ]; then
  log "Updating existing app in $APP_DIR"
  git -C "$APP_DIR" pull --ff-only
else
  log "Cloning app into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"
npm ci

log ""
log "Install complete."
log "Start the app with:"
log "  cd $APP_DIR"
log "  PORT=$PORT npm start"
log ""
log "Then open:"
log "  http://localhost:$PORT"
