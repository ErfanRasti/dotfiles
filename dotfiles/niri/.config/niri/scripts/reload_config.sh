#!/usr/bin/env bash

if pgrep -fx "qs -c noctalia-shell"; then
  pkill -fx "qs -c noctalia-shell"
fi
qs -c noctalia-shell
