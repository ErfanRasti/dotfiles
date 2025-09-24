#!/usr/bin/env bash
# battery-watcher.sh — Wayland-friendly, UPower event loop, minimal CPU

# ---- Config (edit if you like) ----
LOW=30
CRIT=15
DANGER=5
SUSPEND_AT=2                 # suspend when discharging at/below this %
PPD_LO_THRESH=20             # set power-saver at/under this %
NOTIFY_APP="Battery Watcher" # notification app-name

# Nerd Font glyphs (Font Awesome in Nerd Fonts)
ICON_BAT0="" # empty
ICON_BAT1=""
ICON_BAT2=""
ICON_BAT3=""
ICON_BAT4="" # full
ICON_PLUG=""
ICON_BOLT=""
ICON_WARN=""
ICON_OK=""

# ---- Helpers ----
notify() {
  # Use glyphs in title; icon hint left generic for compatibility with Wayland notifiers
  local urgency="$1"
  shift
  local title="$1"
  shift
  local body="$*"
  # -u: normal|low|critical
  notify-send -u "$urgency" -a "$NOTIFY_APP" "$title" "$body"
}

percent_to_icon() {
  local p="$1"
  if ((p <= 10)); then
    echo "$ICON_BAT0"
  elif ((p <= 30)); then
    echo "$ICON_BAT1"
  elif ((p <= 55)); then
    echo "$ICON_BAT2"
  elif ((p <= 80)); then
    echo "$ICON_BAT3"
  else
    echo "$ICON_BAT4"
  fi
}

set_ppd_mode() {
  # Requires power-profiles-daemon (powerprofilesctl)
  local mode="$1" # "power-saver" | "balanced" | "performance"
  command -v powerprofilesctl >/dev/null 2>&1 || return 0
  # Only change if different (avoids log spam and dbus churn)
  local cur
  cur="$(powerprofilesctl get 2>/dev/null || echo "")"
  if [[ "$cur" != "$mode" ]]; then
    powerprofilesctl set "$mode" 2>/dev/null
    notify normal "$ICON_OK  Power profile: $mode" "Switched by battery watcher."
  fi
}

suspend_now() {
  notify critical "$ICON_WARN  Suspending (2% battery)" "Saving your session…"
  systemctl suspend 2>/dev/null || loginctl suspend 2>/dev/null
}

# ---- Discover UPower devices ----
command -v upower >/dev/null 2>&1 || {
  notify critical "$ICON_WARN  UPower not found" "Install upower and try again."
  exit 1
}

BATTERY_PATH="$(upower -e | grep -i '/battery_' | head -n1)"
LINE_PATH="$(upower -e | grep -i '/line_power_' | head -n1)"
if [[ -z "$BATTERY_PATH" ]]; then
  notify critical "$ICON_WARN  No battery device" "UPower didn't report any battery."
  exit 1
fi

# ---- State tracking to avoid duplicate notifications ----
last_level="init"       # init|ok|low|critical|danger
last_state="unknown"    # charging|discharging|fully-charged|pending|unknown
ppd_powersave_applied=0 # 0/1
notified_charge=0
notified_discharge=0
did_suspend=0

# ---- Read current info ----
read_battery() {
  # Outputs: STATE PERCENT INT_PERCENT
  # Use IFS to parse cleanly and avoid subshells wherever possible
  local info state percent
  info="$(upower -i "$BATTERY_PATH")"
  state="$(printf '%s\n' "$info" | awk -F: '/state/ {gsub(/[[:space:]]/,"",$2); print $2; exit}')"
  percent="$(printf '%s\n' "$info" | awk -F: '/percentage/ {gsub(/[[:space:]]|%/,"",$2); print $2; exit}')"
  # Fallbacks
  [[ -z "$state" ]] && state="unknown"
  [[ -z "$percent" ]] && percent="0"
  printf '%s %s %d\n' "$state" "$percent" "$percent"
}

# ---- Core check ----
check_and_act() {
  # shellcheck disable=SC2155
  local readout="$(read_battery)"
  # Use IFS for robust parsing (Wayland-friendly, minimal allocations)
  local IFS=" "
  # shellcheck disable=SC2086
  set -- $readout
  local state="$1" pct="$2" ipct="$3"

  # Charging/discharging notifications
  if [[ "$state" != "$last_state" ]]; then
    if [[ "$state" == "charging" || "$state" == "fully-charged" ]]; then
      if ((notified_charge == 0)); then
        notify normal "$ICON_PLUG  Charging" "$ICON_BOLT Now at ${pct}%."
        notified_charge=1
        notified_discharge=0
      fi
      # Reset PPD to balanced if plugged and > 5%
      if ((ipct > 5)); then
        set_ppd_mode "balanced"
        ppd_powersave_applied=0
      fi
    elif [[ "$state" == "discharging" ]]; then
      if ((notified_discharge == 0)); then
        notify normal "$(percent_to_icon "$ipct")  Discharging" "Battery at ${pct}%."
        notified_discharge=1
        notified_charge=0
      fi
    fi
    last_state="$state"
  fi

  # Threshold notifications (only when discharging)
  if [[ "$state" == "discharging" ]]; then
    # Suspend hard-stop
    if ((ipct <= SUSPEND_AT)) && ((did_suspend == 0)); then
      suspend_now
      did_suspend=1
      return
    fi

    # Power-saver at/under PPD_LO_THRESH
    if ((ipct <= PPD_LO_THRESH)) && ((ppd_powersave_applied == 0)); then
      set_ppd_mode "power-saver"
      ppd_powersave_applied=1
    fi

    # Determine level bucket
    local level="ok" urgency="normal" label="OK"
    if ((ipct <= DANGER)); then
      level="danger"
      urgency="critical"
      label="DANGER"
    elif ((ipct <= CRIT)); then
      level="critical"
      urgency="critical"
      label="CRITICAL"
    elif ((ipct <= LOW)); then
      level="low"
      urgency="normal"
      label="Low"
    fi

    if [[ "$level" != "$last_level" ]]; then
      case "$level" in
      low)
        notify "$urgency" "$(percent_to_icon "$ipct")  Low battery (${pct}%)" \
          "Connect power soon."
        ;;
      critical)
        notify "$urgency" "$ICON_WARN  Critical battery (${pct}%)" \
          "Please plug in now."
        ;;
      danger)
        notify "$urgency" "$ICON_WARN  ${pct}% Battery — DANGER" \
          "System will suspend at ${SUSPEND_AT}%."
        ;;
      ok)
        # Crossing back upward while still discharging: optionally notify
        :
        ;;
      esac
      last_level="$level"
    fi
  else
    # When plugged in: clear low-state so future drops will notify again and reset suspend flag
    last_level="ok"
    did_suspend=0
    # If we got plugged in and >5%, ensure balanced (handled above on state change as well)
    if ((ipct > 5)); then
      set_ppd_mode "balanced"
      ppd_powersave_applied=0
    fi
  fi
}

# ---- Initial check & a quiet settle timer to avoid startup storm ----
check_and_act

# ---- Event loop (Wayland-friendly): UPower DBus monitor ----
# This blocks and only wakes on power events; extremely low CPU use.
# We watch for any change on our battery path and then run check_and_act.
upower --monitor 2>/dev/null | while IFS= read -r line; do
  # Only react to our battery device or line_power (plug/unplug)
  if [[ "$line" == *"$BATTERY_PATH"* || (-n "$LINE_PATH" && "$line" == *"$LINE_PATH"*) ]]; then
    check_and_act
  fi
done
