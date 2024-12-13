#!/bin/sh
rm -rf tmp/pids/server.pid
printenv >> /etc/environment
exec "$@"
