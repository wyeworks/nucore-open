#!/bin/sh
rm -rf tmp/pids/server.pid

if [ -d /shared ]; then
  mkdir -p /shared/uploads
  ln -nfs /shared/uploads /app/public/uploads
fi

exec "$@"
