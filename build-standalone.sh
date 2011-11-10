#!/bin/bash
# This will build a standalone executable.
# This is NOT necessary. Only use this if you want to make a singly binary
# that you can easily distribute to a lot of machines, instead of having
# to install it on each and every machine.
# You will need to install pp:
#   sudo cpanm pp

pp -P -o stackattack bin/stackattack
