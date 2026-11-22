#!/usr/bin/env bash
# Stop every lab named instance (pid files are per instance). Run with sudo.
for f in /run/named-root.pid /var/cache/bind/{unsigned,alpha,signed,beta,gamma,recursive1,recursive2}.pid; do
  [ -f "$f" ] && kill "$(cat "$f")" && echo "stopped $f"
done
exit 0
