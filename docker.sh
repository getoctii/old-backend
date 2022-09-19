#!/bin/bash

#Define cleanup procedure
cleanup() {
  lapis term
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

#Execute a command
"${@}" &

#Wait
wait $!
