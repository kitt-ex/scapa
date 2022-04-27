#!/bin/sh
COV=$(mix coveralls | grep TOTAL)
if [ "$COV" == "[TOTAL] 100.0%" ]; then
  echo "Code coverage is 100%"
  exit 0
else
  echo "Code coverage < 100%"
  exit 1
fi
