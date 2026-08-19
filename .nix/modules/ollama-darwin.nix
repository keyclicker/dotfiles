{ pkgs, ... }:

{
  # Run as a user agent so Ollama uses the user's model store and Metal GPU.
  # OpenCode connects to this loopback-only API.
  launchd.user.agents.ollama = {
    command = "${pkgs.ollama}/bin/ollama serve";

    environment = {
      OLLAMA_CONTEXT_LENGTH = "8192";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_HOST = "127.0.0.1:11434";
      OLLAMA_KEEP_ALIVE = "4m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NO_CLOUD = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };

    serviceConfig = {
      KeepAlive = true;
      ProcessType = "Interactive";
      RunAtLoad = true;
      ThrottleInterval = 30;
    };
  };
}
