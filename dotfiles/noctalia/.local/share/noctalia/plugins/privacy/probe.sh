#!/usr/bin/env bash
# One snapshot of what is using the screen, camera, microphone and location, as one
# JSON line: {"screen":[apps],"camera":[apps],"mic":[apps],"location":[apps]}.
# Polled by widget.luau.
#
#   mic      : running capture streams (Stream/Input/Audio), minus what only listens
#              to the speakers or is plumbing: the audio visualizer
#              (stream.capture.sink), *.monitor targets, virtual loopbacks (the
#              meet mic's share_in/meet_mic_in), pavucontrol's peak meters, noctalia
#   camera   : running video consumers linked to a v4l2/libcamera source, a running
#              camera source nobody claims, and apps holding /dev/video* directly
#              (bypassing PipeWire)
#   screen   : running video consumers linked to a screencast (a non-camera
#              Video/Source or a portal's Stream/Output/Video), or such a source
#              running on its own
#   location : apps GeoClue is locating for (browsers, the location portal), named
#              from GeoClue's debug log; see below
#
# $1 $2 $3: noctalia's own shell.privacy.{mic,cam,screen}_filter_regex (app names
# matching them are ignored, as by the built-in privacy widget); empty = none.
#
# Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

# Apps opening the camera device themselves, one per line; PipeWire/WirePlumber
# holding it is what the PipeWire graph already reports.
direct=
while read -r fd; do
  read -r comm < "${fd%/fd}/comm" || continue
  case $comm in pipewire | wireplumber | .pipewire-* | .wireplumber-*) ;; *) direct+=$comm$'\n' ;; esac
done < <(find /proc/[0-9]*/fd -maxdepth 1 -lname '/dev/video*' -printf '%h\n' 2>/dev/null)

# Apps GeoClue is locating for, one per line. GeoClue hides a client's DesktopId
# (and whether it's active) from everyone but the app holding it, so the names come
# from its debug log (G_MESSAGES_DEBUG, host/modules/location.nix): "'zen'
# started." / "'zen' stopped." in the current geoclue run, read only while the
# Manager's public InUse is true (some client is actually locating). A bare client
# object doesn't count: Zen keeps an idle one after a site asks, even when the
# agent refused it (Location off). An active client the log doesn't name still
# counts, as "Location". Timezone
# daemons are system plumbing, not shown (as on a Mac).
# Only asks a running geoclue: busctl's --auto-start=no isn't honoured, and polling
# would restart geoclue every time it idles out after 60 s.
GC=org.freedesktop.GeoClue2
location=
if [[ $(busctl --system call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
  NameHasOwner s $GC 2>/dev/null) == "b true" ]] &&
  [[ $(busctl --system get-property $GC /org/freedesktop/GeoClue2/Manager $GC.Manager InUse 2>/dev/null) == "b true" ]]; then
  ids=$(journalctl _SYSTEMD_UNIT=geoclue.service _PID="$(systemctl show -p MainPID --value geoclue.service)" \
    -o cat --no-pager 2>/dev/null | awk -v q="'" '
      $NF == "started." || $NF == "stopped." {
        if (substr($0, 1, 1) != q) next
        seen = 1; id = substr($0, 2, length($0) - length($NF) - 3); on[id] = ($NF == "started.")
      }
      END {
        if (!seen) print "Location"
        for (id in on) if (on[id] && id !~ /^(automatic-timezoned|localtimed|gnome-datetime-panel)$/) print id
      }')
  # A DesktopId's app name from its .desktop file ("zen" -> "Zen Browser"), else the id.
  while read -r id; do
    name=$id
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS//:/ }; do
      [[ -r $d/applications/$id.desktop ]] || continue
      while IFS= read -r l; do [[ $l == Name=* ]] && { name=${l#Name=}; break; }; done < "$d/applications/$id.desktop"
      break
    done
    location+=$name$'\n'
  done <<< "$ids"
fi

pw-dump 2>/dev/null | jq -c \
  --arg micRe "${1:-}" --arg camRe "${2:-}" --arg screenRe "${3:-}" \
  --arg direct "$direct" --arg location "$location" '
  def lines: split("\n") | map(select(. != ""));
  def truthy: tostring == "true";
  def app: .p["application.name"] // .p["application.process.binary"]
           // .p["node.description"] // .p["node.name"] // "?";
  def cls: .p["media.class"] // "";
  def running: .state == "running";
  def isCamera: cls == "Video/Source" and ((.p["device.api"] // "") | test("^(v4l2|libcamera)$"));
  def isScreen: (cls == "Video/Source" and (isCamera | not)) or cls == "Stream/Output/Video";
  def drop($re): if $re == "" then . else map(select(test($re) | not)) end;

  ([.[] | select(.type == "PipeWire:Interface:Node")
        | {id, state: .info.state, p: (.info.props // {})}]) as $nodes
  | ([.[] | select(.type == "PipeWire:Interface:Link")
          | {o: .info["output-node-id"], i: .info["input-node-id"]}]) as $links
  | ([$nodes[] | select(isCamera) | .id]) as $cams
  | ([$nodes[] | select(isScreen) | .id]) as $screens
  | ([$nodes[] | select(cls == "Stream/Input/Video" and running)
       | . as $c | {app: app, from: [$links[] | select(.i == $c.id) | .o]}]) as $viewers
  | {
      screen: (
        ([$viewers[] | select(any(.from[]; IN($screens[]))) | .app]
         + [$nodes[] | select(isScreen and running) | . as $s
                    | select(any($links[]; .o == $s.id) | not) | app])
        | unique | drop($screenRe)),
      camera: (
        [$viewers[] | select(any(.from[]; IN($cams[]))) | .app] as $apps
        | ($apps
           + (if $apps == [] and any($nodes[]; isCamera and running) then ["Camera"] else [] end)
           + ($direct | lines))
        | unique | drop($camRe)),
      mic: (
        [$nodes[] | select(cls == "Stream/Input/Audio" and running
             and (.p["node.virtual"] | truthy | not)
             and (.p["stream.capture.sink"] | truthy | not)
             and ((.p["target.object"] // "" | tostring) | endswith(".monitor") | not)
             and ((.p["media.name"] // "") != "Peak detect")
             and ((.p["application.process.binary"] // "") | test("noctalia") | not))
         | app]
        | unique | drop($micRe)),
      location: ($location | lines | unique)
    }'
