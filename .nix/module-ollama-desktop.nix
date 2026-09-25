# Ollama on loopback, shared through Tailscale TCP forwarding on both
# platforms: one model loaded at a time, short keep-alive, no cloud.
# The mac runs it as a launchd user agent so it uses the user's model
# store and the Metal GPU; NixOS has services.ollama (CPU only in a
# VM, bare metal sets services.ollama.acceleration). nix-darwin has
# no services.ollama and NixOS no launchd, and mkIf cannot hide an
# unknown option, so the branch is chosen up front on `os`, which
# flake.nix passes as a special arg (pkgs is not available this early).
{ pkgs, os, ... }:

let
  tuning = {
    OLLAMA_CONTEXT_LENGTH = "8192";
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KEEP_ALIVE = "4m";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    OLLAMA_MAX_LOADED_MODELS = "1";
    OLLAMA_NO_CLOUD = "1";
    OLLAMA_NUM_PARALLEL = "1";
  };
in
if os == "darwin" then
  {
    # The CLI; services.ollama puts it on PATH itself on NixOS.
    environment.systemPackages = [ pkgs.ollama ];

    # Use the CLI shipped with the Homebrew Tailscale app, not a second
    # tailscaled installation. Foreground Serve follows launchd's lifetime.
    launchd.user.agents.ollama-tailnet = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
          "serve"
          "--tcp=11434"
          "tcp://127.0.0.1:11434"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 15;
      };
    };

    launchd.user.agents.ollama = {
      command = "${pkgs.ollama}/bin/ollama serve";
      environment = tuning // {
        OLLAMA_HOST = "127.0.0.1:11434";
      };

      serviceConfig = {
        KeepAlive = true;
        ProcessType = "Interactive";
        RunAtLoad = true;
        ThrottleInterval = 30;
      };
    };
  }
else
  {
    systemd.services.ollama-tailnet = {
      description = "Expose Ollama over Tailscale";
      wantedBy = [ "multi-user.target" ];
      wants = [
        "tailscaled.service"
        "ollama.service"
      ];
      after = [
        "tailscaled.service"
        "ollama.service"
      ];
      serviceConfig = {
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --tcp=11434 tcp://127.0.0.1:11434";
        Restart = "always";
        RestartSec = 15;
      };
    };

    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      environmentVariables = tuning;
    };
  }
