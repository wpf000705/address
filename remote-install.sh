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

compose_cmd() {
  if has_cmd docker && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif has_cmd docker-compose; then
    docker-compose "$@"
  else
    return 127
  fi
}

install_git

docker_available=false
if has_cmd docker && compose_cmd version >/dev/null 2>&1; then
  docker_available=true
else
  install_node20
fi

if [ -d "$APP_DIR/.git" ]; then
  log "Updating existing app in $APP_DIR"
  git -C "$APP_DIR" pull --ff-only
else
  log "Cloning app into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"
if [ "$docker_available" = false ]; then
  npm ci
fi

log ""
log "Install complete."

if [ "$docker_available" = true ]; then
  log "Starting with Docker..."
  PORT="$PORT" compose_cmd up -d --build
  log ""
  log "Docker service is running."
  log "Open on this computer:"
  log "  http://localhost:$PORT"
  if has_cmd hostname; then
    lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    if [ -n "${lan_ip:-}" ]; then
      log "Open from another computer on the same LAN:"
      log "  http://$lan_ip:$PORT"
    fi
  fi
  log ""
  log "View logs:"
  log "  cd $APP_DIR && docker compose logs -f"
else
  log "Docker Compose was not found, so the app was installed but not started in Docker."
  log "Start it with Node:"
  log "  cd $APP_DIR"
  log "  PORT=$PORT npm start"
  log ""
  log "Or install Docker Desktop / Docker Compose, then run:"
  log "  cd $APP_DIR"
  log "  PORT=$PORT docker compose up -d --build"
fi
