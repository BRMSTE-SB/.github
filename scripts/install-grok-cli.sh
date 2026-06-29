#!/usr/bin/env bash
# Install xAI CLI for Grok — no API keys in this script.
# Official: curl -fsSL https://x.ai/cli/install.sh | bash
set -euo pipefail

echo "==> xAI CLI install · BRMSTE human-open lane"
echo "    Official: https://x.ai/cli/install.sh"
echo "    Store XAI_API_KEY in Fort Knox only — never commit keys."

curl -fsSL https://x.ai/cli/install.sh | bash

echo "==> xAI CLI install complete"
echo "    Set XAI_API_KEY in your environment (Fort Knox) before use."
