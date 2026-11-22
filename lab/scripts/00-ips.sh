#!/usr/bin/env bash
# Add the lab addresses to lo (idempotent). Run with sudo.
set -eu
for h in 10 20 30 40 50 60 100 200; do
  ip addr show dev lo | grep -q "172.30.0.$h/" || ip addr add "172.30.0.$h/32" dev lo
done
ip -4 addr show dev lo | grep 172.30.0
