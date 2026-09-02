# ollama on loopback for every desktop, one tuning for both
# platforms: one model loaded at a time, short keep-alive, no cloud.
# The mac runs it as a launchd user agent so it uses the user's model
# store and the Metal GPU; NixOS has services.ollama (CPU only in a
# VM, bare metal sets services.ollama.acceleration). nix-darwin has
# no services.ollama and NixOS no launchd, and mkIf cannot hide an
# unknown option, so the platform is picked by which option tree
# exists.
{ pkgs, options, ... }:

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
{
  config =
    if options.services ? ollama then
      {
        services.ollama = {
          enable = true;
          host = "127.0.0.1";
          environmentVariables = tuning;
        };
      }
    else
      {
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
      };
}
