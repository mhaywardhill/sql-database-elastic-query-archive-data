#!/usr/bin/env bash
set -euo pipefail

fix_yarn_key_if_needed() {
  if [[ -f /etc/apt/sources.list.d/yarn.list ]]; then
    echo "Refreshing Yarn APT keyring to avoid apt update signature failures..."
    if command -v sudo >/dev/null 2>&1; then
      sudo rm -f /usr/share/keyrings/yarn-archive-keyring.gpg
      curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
        | sudo gpg --dearmor --yes --batch -o /usr/share/keyrings/yarn-archive-keyring.gpg
    else
      rm -f /usr/share/keyrings/yarn-archive-keyring.gpg
      curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
        | gpg --dearmor --yes --batch -o /usr/share/keyrings/yarn-archive-keyring.gpg
    fi
  fi
}

install_az_cli() {
  if command -v az >/dev/null 2>&1; then
    echo "Azure CLI already installed: $(az version --query '"\"azure-cli\""' -o tsv 2>/dev/null || echo unknown)"
    return 0
  fi

  echo "Azure CLI not found. Installing..."
  fix_yarn_key_if_needed
  if command -v sudo >/dev/null 2>&1; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  else
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  fi

  command -v az >/dev/null 2>&1
  echo "Azure CLI installed successfully."
}

auto_login_if_configured() {
  if [[ -n "${AZURE_CLIENT_ID:-}" && -n "${AZURE_CLIENT_SECRET:-}" && -n "${AZURE_TENANT_ID:-}" ]]; then
    echo "Attempting Azure CLI service principal login..."
    az login --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --password "$AZURE_CLIENT_SECRET" \
      --tenant "$AZURE_TENANT_ID" \
      --output none || true
  else
    echo "Service principal env vars not set. Skipping auto-login."
  fi
}

install_az_cli
auto_login_if_configured
