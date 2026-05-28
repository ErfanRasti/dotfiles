#!/bin/bash

find_non_tun_default() {
  ip route show default | grep -v 'dev tun' | grep -oP 'dev \K[^ ]+' | head -1
}

find_tun_device() {
  openvpn3 sessions-list 2>/dev/null | grep -oP 'Device: \Ktun\d+'
}

disconnect_tun() {
  sudo ip route delete default
  sudo ip route replace default via "$GATEWAY_V4" dev "$INTERFACE"
}

connect_tun() {
  sudo ip route replace default dev "$TUN_DEVICE"
}

disconnect_openvpn3() {
  for s in $(openvpn3 sessions-list | awk '/Path/ {print $2}'); do
    openvpn3 session-manage --session-path "$s" --disconnect
  done
}

connect_openvpn3() {
  openvpn3 session-start --config "$CONFIGS_PATH"/config.ovpn
}

download_ips() {
  if [ ! -f "$FILE_V4" ]; then
    # Download IPv4 ranges
    wget -qO "$FILE_V4" http://www.ipdeny.com/ipblocks/data/countries/"$COUNTRY_CODE".zone
  fi

  if [ ! -f "$FILE_V4" ]; then
    # Download IPv6 ranges
    wget -qO "$FILE_V6" http://www.ipdeny.com/ipv6/ipaddresses/blocks/"$COUNTRY_CODE".zone
  fi
}

bypass() {
  download_ips

  echo "Adding IPv4 routes..."

  while read subnet; do
    sudo ip route replace "$subnet" via "$GATEWAY_V4" dev "$INTERFACE"
  done <"$FILE_V4"

  echo "Adding IPv6 routes..."

  while read -r subnet; do
    sudo ip -6 route replace "$subnet" via "$GATEWAY_V6" dev "$INTERFACE"
  done <"$FILE_V6"

  echo "IPv4 + IPv6 routes added."
}

remove_bypass() {
  while read -r subnet; do
    sudo ip route del "$subnet" 2>/dev/null
  done <"$FILE_V4"

  echo "IPv4 routes removed."

  while read -r subnet; do
    sudo ip -6 route del "$subnet" 2>/dev/null
  done <"$FILE_V6"

  echo "IPv6 routes removed."

}

bypass_permanent() {
  download_ips

  sudo mkdir -p /etc/iproute2
  if ! grep -q "^$TABLE_ID bypass" /etc/iproute2/rt_tables 2>/dev/null; then
    echo "$TABLE_ID bypass" | sudo tee -a /etc/iproute2/rt_tables
  fi

  echo "Adding IPv4 routes permanently..."

  while read -r subnet; do
    [ -z "$subnet" ] && continue
    sudo nmcli connection modify "$CONN_NAME" +ipv4.routes "$subnet $GATEWAY_V4 table=$TABLE_ID" >/dev/null 2>&1
  done <"$FILE_V4"

  echo "Adding IPv6 routes permanently..."

  while read -r subnet; do
    [ -z "$subnet" ] && continue
    sudo nmcli device connection "$CONN_NAME" +ipv6.routes "$subnet $GATEWAY_V6 table=$TABLE_ID" >/dev/null 2>&1
  done <"$FILE_V6"

  # Apply the changes
  sudo ip rule add from all lookup $TABLE_ID priority 5000
  sudo nmcli device reapply "$INTERFACE"

  echo "IPv4 + IPv6 routes added permanently to $INTERFACE. They will survive reboot."
}

remove_bypass_permanent() {
  # Clear ALL ipv4 routes from the connection
  sudo nmcli connection modify "$CONN_NAME" ipv4.routes ""

  # Clear ALL ipv6 routes from the connection
  sudo nmcli connection modify "$CONN_NAME" ipv6.routes ""

  # Remove the ip rule
  sudo ip rule del from all lookup $TABLE_ID priority 5000 2>/dev/null ||
    sudo ip rule del from all lookup $TABLE_ID 2>/dev/null

  # Remove table entry
  sudo sed -i "/^$TABLE_ID bypass$/d" /etc/iproute2/rt_tables

  # Apply changes
  sudo nmcli device reapply "$INTERFACE"

  echo "All bypass routes removed. Connection is back to original state."
}

main() {

  CONFIGS_PATH="$HOME/programs/openvpn"
  INTERFACE="$(find_non_tun_default)"
  COUNTRY_CODE=$(cat "$CONFIGS_PATH/country_code" | tr -d '[:space:]')

  GATEWAY_V4=$(ip route show default | grep -v 'dev tun' | awk '/default via / {print $3}' | head -1)
  GATEWAY_V6=$(ip -6 route show default | grep -v 'dev tun' | awk '/default via / {print $3}' | head -1)
  GATEWAY_V4="${GATEWAY_V6:-192.168.1.1}"
  GATEWAY_V6="${GATEWAY_V6:-fe80::1}"

  FILE_V4=/tmp/"$COUNTRY_CODE"4.zone
  FILE_V6=/tmp/"$COUNTRY_CODE"6.zone

  # CONN_NAME=$(nmcli -g GENERAL.CONNECTION device show "$INTERFACE")
  CONN_NAME=$(nmcli -t -f NAME,DEVICE connection show | grep ":$INTERFACE$" | cut -d: -f1)
  TABLE_ID=100

  COMMAND="$1"

  case "$COMMAND" in
  connect)
    echo "Stopping VPN..."
    disconnect_openvpn3

    echo "Starting VPN..."
    connect_openvpn3

    echo "Switching default route to tun..."
    TUN_DEVICE="$(find_tun_device)"
    connect_tun

    if [[ "$2" == "--bypass" ]]; then
      echo "Adding bypass..."
      bypass
    fi

    openvpn3 sessions-list
    ;;

  disconnect)

    if [[ "$2" == "--bypass" ]]; then
      echo "Removing bypass..."
      remove_bypass
    fi

    echo "Restoring normal gateway..."
    disconnect_tun

    echo "Stopping VPN..."
    disconnect_openvpn3

    openvpn3 sessions-list
    ;;
  bypass)

    echo "Adding bypass..."
    bypass
    ;;
  remove-bypass)
    echo "Removing bypass..."
    remove_bypass
    ;;
  bypass-perm)
    bypass_permanent
    ;;
  remove-bypass-perm)
    echo "Removing bypass..."
    remove_bypass_permanent
    ;;
  status)
    openvpn3 sessions-list
    ;;

  *)
    echo "Usage:"
    echo "$0 connect [--bypass]"
    echo "$0 disconnect [--bypass]"
    echo "$0 bypass"
    echo "$0 remove-bypass"
    echo "$0 status"
    exit 1
    ;;
  esac
}

main "$@"
