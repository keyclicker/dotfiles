# The mac desktop below the apps, what module-desktop-linux.nix is
# on NixOS: the system-level knobs of the session. The session itself
# (yabai, skhd, karabiner) is packages and casks plus dotfiles.
{ ... }:

{
  system.defaults.NSGlobalDomain = {
    # Move windows by holding Control+Command and dragging anywhere.
    NSWindowShouldDragOnGesture = true;
    # No alternative characters on hold.
    ApplePressAndHoldEnabled = false;
  };

  # Keep Touch ID available inside long-running tmux sessions.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
