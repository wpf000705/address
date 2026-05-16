#!/usr/bin/env sh
set -eu

APP_NAME="create-address"
REPO_URL="${REPO_URL:-https://github.com/wpf000705/address.git}"
APP_DIR="${APP_DIR:-$HOME/${APP_NAME}}"
PORT="${PORT:-3000}"
HEALTH_RETRIES="${HEALTH_RETRIES:-30}"
DOCKER_START_RETRIES="${DOCKER_START_RETRIES:-60}"

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

install_docker() {
  if docker_compose_available; then
    return
  fi

  log "Docker Compose was not found. Installing Docker..."

  if is_debian_like; then
    run_as_root apt-get update
    run_as_root apt-get install -y ca-certificates curl
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    run_as_root sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
  elif is_macos && has_cmd brew; then
    brew install --cask docker || true
    if has_cmd open; then
      open -a Docker || true
    fi
  else
    log "Could not install Docker automatically on this system."
    log "Please install Docker Desktop or Docker Engine with Docker Compose, then run this installer again."
    exit 1
  fi

  if ! docker_compose_available; then
    log "Docker installation finished, but Docker Compose is still unavailable."
    log "Please restart your terminal or install Docker Compose, then run this installer again."
    exit 1
  fi
}

compose_cmd() {
  if has_cmd docker && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif has_cmd docker && has_cmd sudo && sudo docker compose version >/dev/null 2>&1; then
    sudo docker compose "$@"
  elif has_cmd docker-compose && docker-compose version >/dev/null 2>&1; then
    docker-compose "$@"
  elif has_cmd docker-compose && has_cmd sudo && sudo docker-compose version >/dev/null 2>&1; then
    sudo docker-compose "$@"
  else
    return 127
  fi
}

docker_compose_available() {
  has_cmd docker && compose_cmd version >/dev/null 2>&1
}

docker_running() {
  if has_cmd docker && docker info >/dev/null 2>&1; then
    return 0
  fi
  has_cmd docker && has_cmd sudo && sudo docker info >/dev/null 2>&1
}

start_docker() {
  if docker_running; then
    return 0
  fi

  if is_macos; then
    if has_cmd open; then
      open -a Docker || true
    fi
  else
    if has_cmd systemctl; then
      run_as_root systemctl enable --now docker || true
    fi
    if ! docker_running && has_cmd service; then
      run_as_root service docker start || true
    fi
  fi

  i=1
  while [ "$i" -le "$DOCKER_START_RETRIES" ]; do
    if docker_running; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done

  return 1
}

check_health() {
  url="http://127.0.0.1:$PORT/api/health"
  i=1

  while [ "$i" -le "$HEALTH_RETRIES" ]; do
    if has_cmd curl && curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi

    sleep 1
    i=$((i + 1))
  done

  return 1
}

install_git
install_docker

if [ -d "$APP_DIR/.git" ]; then
  log "Updating existing app in $APP_DIR"
  git -C "$APP_DIR" pull --ff-only
else
  log "Cloning app into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

log ""
log "Install complete."

if ! start_docker; then
  log "Docker is installed, but the Docker service is not running."
  if is_macos; then
    log "Please start Docker Desktop, wait until it finishes starting, then run this installer again."
  else
    log "Please start Docker, for example:"
    log "  sudo systemctl start docker"
    log "Then run this installer again."
  fi
  exit 1
fi

log "Starting with Docker..."
PORT="$PORT" compose_cmd up -d --build

if ! check_health; then
  log ""
  log "Docker container started, but the health check did not pass at http://127.0.0.1:$PORT/api/health"
  log "Check logs with:"
  log "  cd $APP_DIR && docker compose logs -f"
  exit 1
fi

log ""
log "Docker service is running and health check passed."
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
