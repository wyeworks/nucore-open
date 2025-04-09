#!/bin/sh
rm -rf tmp/pids/server.pid

if [ -d /shared ]; then
  create_symlink=true

  if [ -d /app/public/uploads ]; then
    if [ ! -L /app/public/uploads ]; then
      if [ "$(ls -A /app/public/uploads 2>/dev/null)" ]; then
        echo "Warning: /app/public/uploads contains files, not creating symlink"
        create_symlink=false
      else
        rm -rf /app/public/uploads
      fi
    fi
  fi

  if [ "$create_symlink" = true ]; then
    ln -nfs /shared /app/public/uploads
  fi
fi

printenv >> /etc/environment
exec "$@"
