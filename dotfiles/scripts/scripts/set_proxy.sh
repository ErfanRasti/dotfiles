#!/usr/bin/env bash
# GNOME + environment proxy manager

quit() {
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return "$1"
  else
    exit "$1"
  fi
}

# ========== Core function: auto-read GNOME proxy ==========
apply_gnome_proxy() {
  local proxy_mode
  proxy_mode=$(gsettings get org.gnome.system.proxy mode | tr -d "'")

  if [[ "$proxy_mode" == "manual" ]]; then

    set_proxy_var() {
      local type=$1
      local envvar=$2

      local host port
      host=$(gsettings get org.gnome.system.proxy."$type" host | tr -d "'")
      port=$(gsettings get org.gnome.system.proxy."$type" port)

      local scheme="${type}://"

      if [[ -n "$host" && "$host" != "''" && "$port" != "0" ]]; then
        export "$envvar=$scheme$host:$port"
      else
        unset "$envvar"
      fi
    }

    # per-proxy variables
    set_proxy_var http http_proxy
    set_proxy_var http HTTP_PROXY
    set_proxy_var http https_proxy
    set_proxy_var http HTTPS_PROXY
    set_proxy_var http ftp_proxy
    set_proxy_var http FTP_PROXY
    set_proxy_var socks socks_proxy
    set_proxy_var socks SOCKS_PROXY

    # ALL_PROXY = socks
    if [[ -n "$socks_proxy" ]]; then
      export ALL_PROXY="$socks_proxy"
      export all_proxy="$socks_proxy"
    else
      unset ALL_PROXY all_proxy
    fi

    # no_proxy
    local ignore
    ignore=$(gsettings get org.gnome.system.proxy ignore-hosts | tr -d "[]'" | tr ',' ' ')
    if [[ -n "$ignore" ]]; then
      local ignored_joined
      ignored_joined=$(echo "$ignore" | tr ' ' ',')
      export no_proxy="$ignored_joined"
      export NO_PROXY="$ignored_joined"
    else
      unset no_proxy NO_PROXY
    fi

  elif [[ "$proxy_mode" == "none" ]]; then
    unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY socks_proxy SOCKS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
  fi
}

# ========== Argument-handling helper functions ==========

# Unset both GNOME and shell proxies
unset_all_proxy() {
  # unset environment variables
  unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY socks_proxy SOCKS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY

  # unset GNOME proxies
  gsettings set org.gnome.system.proxy mode 'none'
  gsettings reset-recursively org.gnome.system.proxy.http
  gsettings reset-recursively org.gnome.system.proxy.https
  gsettings reset-recursively org.gnome.system.proxy.ftp
  gsettings reset-recursively org.gnome.system.proxy.socks
  gsettings reset org.gnome.system.proxy ignore-hosts
}

# Set all proxies (using provided host + port)
set_all_proxy() {
  local host=$1
  local port=$2
  local use_ignored_hosts=${3:-1}
  local ignored_default="localhost,127.0.0.0/8,::1"

  # Set GNOME mode
  gsettings set org.gnome.system.proxy mode 'manual'

  # Set HTTP/HTTPS/FTP/SOCKS proxies
  gsettings set org.gnome.system.proxy.http host "'$host'"
  gsettings set org.gnome.system.proxy.http port "$port"
  gsettings set org.gnome.system.proxy.https host "'$host'"
  gsettings set org.gnome.system.proxy.https port "$port"
  gsettings set org.gnome.system.proxy.ftp host "'$host'"
  gsettings set org.gnome.system.proxy.ftp port "$port"
  gsettings set org.gnome.system.proxy.socks host "'$host'"
  gsettings set org.gnome.system.proxy.socks port "$port"

  # Apply to environment as well
  export http_proxy="http://$host:$port"
  export https_proxy="http://$host:$port"
  export ftp_proxy="http://$host:$port"
  export socks_proxy="socks://$host:$port"
  export all_proxy="$socks_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export SOCKS_PROXY="$socks_proxy"
  export FTP_PROXY="$ftp_proxy"
  export ALL_PROXY="$socks_proxy"

  if [[ "$use_ignored_hosts" -eq 1 ]]; then
    export no_proxy="$ignored_default"
    export NO_PROXY="$ignored_default"
    gsettings set org.gnome.system.proxy ignore-hosts \
      "['localhost','127.0.0.0/8','::1']"
  else
    unset no_proxy NO_PROXY
    gsettings reset org.gnome.system.proxy ignore-hosts
  fi
}

print_help() {
  local script_name
  script_name=$(basename "$0")

  cat <<EOF
Usage:
  $script_name
      Auto-detect GNOME proxy settings and apply them to the current environment.

  $script_name -u | --unset
      Unset all proxy settings from both GNOME and terminal environment variables.

  $script_name -s | --set <IP> <PORT>
      Set HTTP, HTTPS, FTP, SOCKS, and ALL_PROXY for both GNOME and terminal.
      Optional:
        -i | --ignored-hosts     Add "localhost,127.0.0.0/8,::1" to no_proxy, NO_PROXY, and GNOME ignore-hosts.
                            If omitted, no_proxy and NO_PROXY will be unset.


  $script_name -h | --help
      Show this help message.
EOF
}

# ========== Argument parsing logic ==========
main() {
  ### Argument parser
  case "${1-}" in
  # No args → apply GNOME → env sync
  "")
    apply_gnome_proxy
    quit 0
    ;;
  -u | --unset)
    [[ $# -eq 1 ]] || {
      echo "Error: $1 takes no extra args." >&2
      exit 1
    }
    unset_all_proxy
    quit 0
    ;;
  -h | --help)
    [[ $# -eq 1 ]] || {
      echo "Error: $1 takes no extra args." >&2
      quit 1
    }
    print_help
    quit 0
    ;;
  -s | --set)
    shift

    use_ignored_hosts=0 # default = OFF
    host=""
    port=""

    for arg in "$@"; do
      case "$arg" in
      -i | --ignored-hosts)
        use_ignored_hosts=1
        ;;
      -*)
        echo "Error: Unknown option '$arg'." >&2
        quit 1
        ;;
      *)
        if [[ -z "$host" ]]; then
          host="$arg"
        elif [[ -z "$port" ]]; then
          port="$arg"
        else
          echo "Error: Too many args for --set. Expected <IP> <PORT>." >&2
          quit 1
        fi
        ;;
      esac
    done

    if [[ -z "$host" || -z "$port" ]]; then
      echo "Error: --set requires <IP> <PORT>." >&2
      quit 1
    fi

    if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
      echo "Error: Invalid port '$port' (must be 1–65535)." >&2
      quit 1
    fi

    set_all_proxy "$host" "$port" "$use_ignored_hosts"
    quit 0
    ;;
  *)
    echo "Error: Unknown argument '$1'." >&2
    echo "Use --help." >&2
    quit 1
    ;;
  esac
}

main "$@"
