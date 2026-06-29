#!/usr/bin/env bash
set -euo pipefail

bash -n scripts/de_thuy.sh
test -f README.md
test -f diagrams/de_thuy_flow.puml

echo "Kiem tra De Thuy thanh cong."
