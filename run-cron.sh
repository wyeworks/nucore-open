#!/bin/sh

# This is invoked by nomad, which calls it as an override command in the job file.
# Update crontab
bundle exec whenever --update-crontab
# Start cron in foreground
cron -foreground -user root
