#!/usr/bin/env sh
set -eu

required_major=20

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required. Please install Node.js ${required_major} or newer."
  exit 1
fi

node_major="$(node -p "Number(process.versions.node.split('.')[0])")"
if [ "$node_major" -lt "$required_major" ]; then
  echo "Node.js ${required_major}+ is required. Current version: $(node -v)"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required. Please reinstall Node.js with npm."
  exit 1
fi

npm ci

echo
echo "Install complete."
echo "Run ./start.sh to start the app."
