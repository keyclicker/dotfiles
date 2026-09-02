# ollama as a system service on loopback, the NixOS counterpart of
# module-ollama-darwin.nix with the same tuning: one model at a
# time, short keep-alive, no cloud. CPU only in a VM; a bare-metal
# host sets services.ollama.acceleration.
{ ... }:

{
  services.ollama = {
    enable = true;
    host = "127.0.0.1";

    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "8192";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KEEP_ALIVE = "4m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NO_CLOUD = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
  };
}
