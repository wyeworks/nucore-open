#!/bin/sh
rm -rf tmp/pids/server.pid
exec "$@"
