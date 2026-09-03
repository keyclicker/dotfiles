# The nvim config for hosts without a ~/.dotfiles checkout (generic
# guests): copied into the store at build time instead of linked to
# the live repo like home-dotfiles.nix does, so a rebuild is what
# updates it. Pairs with module-nvim-minimal.nix, which flags the
# config minimal and supplies prebuilt parsers.
{ ... }:

{
  xdg.configFile."nvim".source = ../.config/nvim;

  # Used for backwards compatibility, please read the changelog before
  # changing: $ home-manager changelog
  home.stateVersion = "26.05";
}
