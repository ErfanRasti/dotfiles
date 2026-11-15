# "Meet-Mic": a mic for calls carrying the laptop mic plus Spotify. Spotify
# plays into "Share to call", a sink apps don't list, which forwards to your
# speakers; Meet-Mic takes its monitor (recording a stream's output breaks
# when it relinks). onChange restarts PipeWire, which reads this only at start.
{ lib, pkgs, ... }:

let
  onChange = "${pkgs.systemd}/bin/systemctl --user try-restart pipewire.service || true";
  # Wait for the target instead of falling back elsewhere
  waitFor = target: {
    "target.object" = target;
    "node.dont-fallback" = true;
    "node.linger" = true;
  };
in
{
  xdg.configFile."pipewire/pipewire.conf.d/90-meet-mic.conf" = {
    inherit onChange;
    text = builtins.toJSON {
      "context.modules" =
        map
          (args: {
            name = "libpipewire-module-loopback";
            inherit args;
          })
          [
            # Share to call -> speakers
            {
              "capture.props" = {
                "node.name" = "share";
                "node.description" = "Share to call";
                "media.class" = "Audio/Sink/Internal";
                "audio.position" = [
                  "FL"
                  "FR"
                ];
              };
            }
            # laptop mic -> Meet-Mic
            {
              "capture.props" = waitFor "alsa_input.pci-0000_00_1f.3.analog-stereo" // {
                "node.name" = "meet_mic_in";
              };
              "playback.props" = {
                "node.name" = "meet_mic";
                "node.description" = "Meet-Mic";
                "media.class" = "Audio/Source";
              };
            }
            # Share to call (pre-volume) -> Meet-Mic
            {
              "capture.props" = waitFor "share" // {
                "stream.capture.sink" = true;
              };
              "playback.props" = waitFor "meet_mic_in";
            }
          ];
    };
  };

  # Stop Chromium/Chrome calls' auto gain from moving the mic volume
  xdg.configFile."pipewire/pipewire-pulse.conf.d/90-meet-mic.conf" = {
    inherit onChange;
    text = builtins.toJSON {
      "pulse.rules" = [
        {
          matches = [
            { "application.process.binary" = "chromium"; }
            { "application.process.binary" = "chrome"; }
          ];
          actions.quirks = [ "block-source-volume" ];
        }
      ];
    };
  };

  # Spotify -> Share to call: copied (its sandbox can't see /nix/store) and
  # read only over native PipeWire, so it loses the PulseAudio socket
  home.activation.spotifyShareToCall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -Dm644 ${
      pkgs.writeText "spotify-share-to-call.conf" (
        builtins.toJSON { "stream.properties"."target.object" = "share"; }
      )
    } "$HOME/.var/app/com.spotify.Client/config/pipewire/client.conf.d/90-meet-mic.conf"
  '';
  services.flatpak.overrides."com.spotify.Client".Context.sockets = [ "!pulseaudio" ];
}
