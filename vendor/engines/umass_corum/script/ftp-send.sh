#!/bin/bash

# In order for this location to work, run the script from the application root, e.g.
# /home/corum/corum.umass.edu/current
script_dir=$PWD/`dirname $0` # The current directory of the script
logfile="$PWD/log/ftp-send.log"
touch $logfile

# PRN files for open journals are rendered here in timestamped directories
# by the umass_corum:render_and_move rake task
journals_dir="$HOME/files/FTP-out"
current_dir="$journals_dir/current"

timeslot=`date +%F-%H-%M`

if [ $RAILS_ENV = "production" ]; then
  destination_server="umgl7056ial@interfaces.umasscs.net"
else
  destination_server="umgl7056ial@interfaces-dev.umasscs.net"
fi

if [ -f $current_dir/*.INPUT ]; then
  date >> $logfile 2>&1
  mv $current_dir/*.INPUT $current_dir/A100.UMGL7056.IAL.INPUT >> $logfile 2>&1
  cd $current_dir >> $logfile 2>&1

  sftp -b $script_dir/ftp-send.sftp $destination_server >> $logfile 2>&1

  mv $current_dir $journals_dir/$timeslot >> $logfile 2>&1
  mkdir $current_dir >> $logfile 2>&1
else
  date >> $logfile 2>&1
  echo "INPUT file doesn't exist" >> $logfile 2>&1
fi

# Remove journal INPUT files older than 30 days
find $journals_dir/* -mtime +30 -exec rm {} \;
