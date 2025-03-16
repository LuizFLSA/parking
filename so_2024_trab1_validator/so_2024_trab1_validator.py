#!/bin/bash
[[ $(ls -A /tmp/user/$UID) ]] && rm -rf /tmp/user/$UID/*
chmod +w .
/home/so/trabalho-2024-2025/utils/parte-1/so_2024_trab1_validator/so_2024_trab1_validator.exe $@
chmod +w .
[[ $(ls -A /tmp/user/$UID) ]] && rm -rf /tmp/user/$UID/*