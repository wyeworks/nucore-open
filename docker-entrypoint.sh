#!/bin/sh
rm -rf tmp/pids/server.pid

if [ -d /shared ]; then
  mkdir -p /shared
  ln -nfs /shared /app/public/uploads
fi

printenv >> /etc/environment
exec "$@"
