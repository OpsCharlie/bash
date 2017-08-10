#!/usr/bin/env bash

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

mesg n

# run inxi information tool
if [ -x "`which inxi 2>&1`" ]; then
    inxi -ISi -v0 -c5
    #inxi -IpRS -v0 -c5
# else
    # [[ -f /var/run/motd.dynamic ]] && cat /var/run/motd.dynamic
fi

echo
#echo "Have a nice day!"
#echo
