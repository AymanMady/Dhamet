#!/usr/bin/env bash
# Creates the Google Play upload key and android/key.properties.
#
# Usage: tool/release/create_upload_key.sh [keystore path]
#
# The keystore is written outside the repository (default:
# ~/keystores/dhametna-upload.jks) with a random password, which only
# android/key.properties records. Neither file is ever committed (see
# android/.gitignore). Back both up: without them, you have to ask Google
# Play support to reset the upload key before you can publish an update.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
keystore="${1:-$HOME/keystores/dhametna-upload.jks}"
properties="$root/android/key.properties"
alias="upload"

if [[ -e "$keystore" ]]; then
  echo "$keystore already exists: nothing done." >&2
  exit 1
fi
if [[ -e "$properties" ]]; then
  echo "$properties already exists: nothing done." >&2
  exit 1
fi

mkdir -p "$(dirname "$keystore")"
password="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)"

# PKCS12 keystores use the same password for the store and the key.
keytool -genkeypair -v \
  -keystore "$keystore" \
  -storetype PKCS12 \
  -alias "$alias" \
  -keyalg RSA -keysize 4096 \
  -validity 10000 \
  -storepass "$password" -keypass "$password" \
  -dname "CN=Dhametna, O=Dhametna, C=MR"
chmod 600 "$keystore"

cat > "$properties" <<EOF
storeFile=$keystore
storePassword=$password
keyAlias=$alias
keyPassword=$password
EOF
chmod 600 "$properties"

echo
echo "Upload key:     $keystore"
echo "Configuration:  $properties"
echo "Back up both files somewhere safe (password manager, encrypted drive)."
keytool -list -v -keystore "$keystore" -storepass "$password" -alias "$alias" \
  | grep -E "SHA1:|SHA256:"
