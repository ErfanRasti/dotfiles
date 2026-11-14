{
  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # rtkit (optional, recommended) allows Pipewire to use the realtime scheduler for increased performance.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment the following
    #jack.enable = true;

    # Share app audio in calls: play an app to "Meet-Mix" (you still hear it)
    # and pick "Meet-Mic" as the mic, which carries that audio plus your voice.
    extraConfig.pipewire."90-meet-mic"."context.modules" =
      map (args: { name = "libpipewire-module-loopback"; inherit args; }) [
        # Meet-Mix sink -> your speakers
        { "capture.props" = { "node.name" = "meet_mix"; "node.description" = "Meet-Mix"; "media.class" = "Audio/Sink"; }; }
        # meet_out sink -> Meet-Mic source: the mix point the call records
        {
          "capture.props" = { "node.name" = "meet_out"; "node.description" = "Meet-Out"; "media.class" = "Audio/Sink"; };
          "playback.props" = { "node.name" = "meet_mic"; "node.description" = "Meet-Mic"; "media.class" = "Audio/Source"; };
        }
        # Meet-Mix -> meet_out
        {
          "capture.props" = { "target.object" = "meet_mix"; "stream.capture.sink" = true; };
          "playback.props"."target.object" = "meet_out";
        }
        # your mic -> meet_out, kept out of your speakers
        { "playback.props"."target.object" = "meet_out"; }
      ];
  };
}
