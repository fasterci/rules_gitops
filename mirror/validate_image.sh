#!/bin/bash
echo "Validating image $1"
$CRANE_BIN validate -v --fast --remote $1
