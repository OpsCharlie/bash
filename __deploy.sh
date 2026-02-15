#!/bin/bash

P=$1
DIR=$(dirname "$(readlink -f "$0")")

if [ "$P" = "" ]; then
  echo Copying files to homedir
  mv ~/.bashrc ~/.bashrc.bak
  mv ~/.bash_profile ~/.bash_profile.bak
  mv ~/.bash_aliases ~/.bash_aliases.bak
  mv ~/.bash_logout ~/.bash_logout.bak
  mv ~/.dircolors ~/.dircolors.bak
  cp "$DIR"/bashrc.sh ~/.bashrc
  cp "$DIR"/bash_profile.sh ~/.bash_profile
  cp "$DIR"/bash_aliases.sh ~/.bash_aliases
  cp "$DIR"/bash_logout.sh ~/.bash_logout
  cp "$DIR"/dircolors ~/.dircolors
  exit $?
fi

if [ "$(expr match "$P" '.*\(:\)')" = ":" ]; then
  echo "Usage:"
  echo "$0               to deploy local"
  echo "$0 user@host     to deploy remote"
  exit 1
fi

ssh "$P" "mv ~/.bashrc ~/.bashrc.bak;\
mv ~/.bash_profile ~/.bash_profile.bak;\
mv ~/.bash_aliases ~/.bash_aliases.bak;\
mv ~/.bash_logout ~/.bash_logout.bak;\
mv ~/.dircolors ~/.dircolors.bak"

sftp "$P" <<EOF
put bashrc.sh       .bashrc
put bash_profile.sh .bash_profile
put bash_aliases.sh .bash_aliases
put bash_logout.sh  .bash_logout
put dircolors       .dircolors
EOF
