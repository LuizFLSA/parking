#!/bin/bash
for arg in "$@"; do
    (( arg < 1 || arg > 7 )) && { >&2 echo "@@VALIDATOR_RESPONSE@@ $0 ERROR $# $@"; exit 1; }
done
>&2 echo "@@VALIDATOR_RESPONSE@@ $0 SUCCESS $# $@"