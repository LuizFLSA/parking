#!/bin/bash
(( $# == 1 || $# == 4 )) && >&2 echo "@@VALIDATOR_RESPONSE@@ $0 SUCCESS $# $@" || >&2 echo "@@VALIDATOR_RESPONSE@@ $0 ERROR $# $@"