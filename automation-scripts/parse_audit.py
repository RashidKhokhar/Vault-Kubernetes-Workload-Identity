#!/usr/bin/env python3
import json
from pathlib import Path

LOG_FILE_PATH = Path(__file__).resolve().parents[1] / "vault-audit.log"
TARGET_SECRET = "secret/data/teams/payment/database"

print(f"🕵️‍♂️ Scanning audit trails for secret dependency: {TARGET_SECRET}...\n")

try:
    with LOG_FILE_PATH.open("r", encoding="utf-8") as file:
        for line in file:
            if not line.strip():
                continue
            log_data = json.loads(line)

            request_path = log_data.get("request", {}).get("path", "")
            auth_meta = log_data.get("auth", {}).get("metadata", {})
            service_account = auth_meta.get("service_account_name", "Unknown")
            namespace = auth_meta.get("service_account_namespace", "Unknown")

            if TARGET_SECRET in request_path:
                print(
                    f"🚨 [MATCH FOUND] Namespace: '{namespace}' | "
                    f"ServiceAccount: '{service_account}' accessed '{request_path}'"
                )
except FileNotFoundError:
    print(
        "❌ Local copy of vault-audit.log not found. "
        "Pull it from the pod first using: 'kubectl cp vault-0:vault/logs/vault-audit.log vault-audit.log'"
    )
