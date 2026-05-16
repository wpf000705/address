#!/usr/bin/env sh
set -eu

if [ ! -d "node_modules" ]; then
  echo "Dependencies are missing. Installing first..."
  sh ./install.sh
fi

npm start
