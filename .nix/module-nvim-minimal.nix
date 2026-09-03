# Minimal nvim for generic guests (vm, container): the same config as
# everywhere else, told to skip everything that needs a toolchain
# (NVIM_MINIMAL, see .config/nvim/init.lua), with tree-sitter parsers
# prebuilt by nixpkgs instead of compiled on the guest. The config
# itself comes from home-nvim-minimal.nix.
{ pkgs, lib, ... }:

let
  # What a guest edits over ssh: configs, compose files, scripts, and
  # enough languages to read a checkout. The dev list nvim-treesitter
  # compiles on full hosts lives in .config/nvim/lua/plugins/treesitter.lua.
  languages = [
    "bash"
    "c"
    "css"
    "diff"
    "dockerfile"
    "git_config"
    "git_rebase"
    "gitcommit"
    "gitignore"
    "go"
    "html"
    "ini"
    "javascript"
    "json"
    "lua"
    "luadoc"
    "markdown"
    "markdown_inline"
    "nix"
    "python"
    "query"
    "regex"
    "rust"
    "sql"
    "ssh_config"
    "toml"
    "typescript"
    "vim"
    "vimdoc"
    "yaml"
  ];

  treesitter = pkgs.vimPlugins.nvim-treesitter;

  # withPlugins hands back parser + query plugins for the languages;
  # queries that inherit from another language (typescript from ecma)
  # carry that one as a dependency, hence the closure.
  closure = plugins: lib.concatMap (p: [ p ] ++ closure (p.dependencies or [ ])) plugins;
  plugins = closure (treesitter.withPlugins (grammars: map (l: grammars.${l}) languages)).dependencies;

  # One directory shaped like nvim-treesitter's own install dir
  # (parser/<lang>.so, queries/<lang>/), so the plugin lists them as
  # installed and never tries to build.
  parsers = pkgs.symlinkJoin {
    name = "nvim-treesitter-parsers";
    paths = lib.unique plugins;
  };
in
{
  environment.sessionVariables = {
    NVIM_MINIMAL = "1";
    NVIM_TREESITTER = "${parsers}";
  };
}
