#!/bin/bash
rm -f app-deployment.yaml
echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-sa
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-app
  namespace: default
  labels:
    app: payment-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-app
  template:
    metadata:
      labels:
        app: payment-app
      annotations:
        "://hashicorp.com": "true"
        "://hashicorp.com": "payment-app-role"
        "://hashicorp.com-secret-config": "secret/data/teams/payment/database"
        "://hashicorp.com-template-config": |
          {{- with secret "secret/data/teams/payment/database" -}}
          DB_USER="{{ .Data.data.username }}"
          DB_PASS="{{ .Data.data.password }}"
          {{- end -}}
    spec:
      serviceAccountName: payment-sa
      containers:
      - name: alpine-app
        image: alpine:latest
        command: ["sh", "-c", "while true; do cat /vault/secrets/config; sleep 15; done"]' > app-deployment.yaml
