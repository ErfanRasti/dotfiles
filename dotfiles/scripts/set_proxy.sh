#!/usr/bin/env bash
# setup proxy
# Get GNOME proxy settings and apply them
apply_gnome_proxy() {
  local proxy_mode
  proxy_mode=$(gsettings get org.gnome.system.proxy mode)
  if [[ "$proxy_mode" == "'manual'" ]]; then
    local proxy_host
    proxy_host=$(gsettings get org.gnome.system.proxy.http host | tr -d "'")
    local proxy_port
    proxy_port=$(gsettings get org.gnome.system.proxy.http port)
    local url="socks5h://$proxy_host:$proxy_port"

    export ALL_PROXY="$url"
    export http_proxy="$url"
    export https_proxy="$url"
    export ftp_proxy="$url"
    export socks_proxy="$url"
    export no_proxy="localhost,127.0.0.1"
    # export no_proxy="localhost,  127.0.0.0/8,  ::1"
  elif [[ "$proxy_mode" == "'none'" ]]; then
    unset http_proxy https_proxy ftp_proxy socks_proxy no_proxy
  fi
}
apply_gnome_proxy
