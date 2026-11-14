# Share app audio in calls: play an app to "Meet-Mix" (you still hear it).
# "Meet-Mic" carries that audio plus your voice; make it the default mic
# once (wpctl set-default) so calls keep it when they reopen the mic, e.g.
# on screen share. Meet-Mix's volume only changes what you hear.
#
# PipeWire reads this only at startup, so onChange restarts it; otherwise the
# nodes don't show up until the next login.
{ pkgs, ... }:

let
  loopback = args: {
    name = "libpipewire-module-loopback";
    inherit args;
  };
in
{
  xdg.configFile."pipewire/pipewire.conf.d/90-meet-mic.conf" = {
    text = builtins.toJSON {
      "context.modules" = map loopback [
        # Meet-Mix sink -> your speakers
        {
          "capture.props" = {
            "node.name" = "meet_mix";
            "node.description" = "Meet-Mix";
            "media.class" = "Audio/Sink";
          };
        }
        # meet_out sink -> Meet-Mic source: the mix point the call records
        {
          "capture.props" = {
            "node.name" = "meet_out";
            "node.description" = "Meet-Out";
            "media.class" = "Audio/Sink";
          };
          "playback.props" = {
            "node.name" = "meet_mic";
            "node.description" = "Meet-Mic";
            "media.class" = "Audio/Source";
          };
        }
        # Meet-Mix -> meet_out
        {
          "capture.props" = {
            "target.object" = "meet_mix";
            "stream.capture.sink" = true;
          };
          "playback.props"."target.object" = "meet_out";
        }
        # laptop mic -> meet_out, kept out of your speakers; never falls back to
        # the default mic, which is Meet-Mic itself
        {
          "capture.props" = {
            "target.object" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
            "node.dont-fallback" = true;
          };
          "playback.props"."target.object" = "meet_out";
        }
      ];
    };
    onChange = ''
      ${pkgs.systemd}/bin/systemctl --user try-restart pipewire.service pipewire-pulse.service wireplumber.service || true
    '';
  };
}
