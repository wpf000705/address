#!/usr/bin/env sh
set -eu

APP_NAME="create-eth-address"
VERSION="$(node -p "require('./package.json').version")"
PACKAGE_NAME="${APP_NAME}-${VERSION}"
DIST_DIR="dist"
STAGING_DIR="${DIST_DIR}/${PACKAGE_NAME}"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R \
  .dockerignore \
  .gitignore \
  Dockerfile \
  README.md \
  docker-compose.yml \
  install.ps1 \
  install.sh \
  package-lock.json \
  package.json \
  remote-install.sh \
  public \
  scripts \
  src \
  start.ps1 \
  start.sh \
  "$STAGING_DIR/"

rm -f "${DIST_DIR}/${PACKAGE_NAME}.tar.gz" "${DIST_DIR}/${PACKAGE_NAME}.zip"

tar -C "$DIST_DIR" -czf "${DIST_DIR}/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

if command -v zip >/dev/null 2>&1; then
  (
    cd "$DIST_DIR"
    zip -qr "${PACKAGE_NAME}.zip" "$PACKAGE_NAME"
  )
fi

printf 'Created:\n'
printf '  %s\n' "${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
if [ -f "${DIST_DIR}/${PACKAGE_NAME}.zip" ]; then
  printf '  %s\n' "${DIST_DIR}/${PACKAGE_NAME}.zip"
fi

rm -rf "$STAGING_DIR"
