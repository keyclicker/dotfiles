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

    # Show every file extension, in Finder and in open/save dialogs.
    AppleShowAllExtensions = true;

    # Fastest key repeat and shortest delay that System Settings
    # offers. Lower is faster; takes effect after logging out.
    KeyRepeat = 2;
    InitialKeyRepeat = 15;
  };

  # ==========================================================
  #                           Dock
  # ==========================================================

  system.defaults.dock = {
    # Hide until the cursor reaches the screen edge.
    autohide = true;
    # No "recent apps" section after the pinned ones.
    show-recents = false;
    # Group windows by app in Mission Control.
    expose-group-apps = true;
    # Icons at 50 px, growing to 80 px under the cursor.
    magnification = true;
    tilesize = 50;
    largesize = 80;
  };

  # ==========================================================
  #                          Finder
  # ==========================================================

  system.defaults.finder = {
    # Show dotfiles; ⇧⌘. still toggles them.
    AppleShowAllFiles = true;
    # New windows open in list view.
    FXPreferredViewStyle = "Nlsv";
    # Folder path and status bar at the bottom of the window.
    ShowPathbar = true;
    ShowStatusBar = true;
    # Folders before files when sorting by name.
    _FXSortFoldersFirst = true;
    # Search the current folder, not the whole Mac.
    FXDefaultSearchScope = "SCcf";
    # Show the internal disk on the Desktop.
    ShowHardDrivesOnDesktop = true;
  };

  # ==========================================================
  #                       Input sources
  # ==========================================================

  # nix-darwin has no layout option, so write HIToolbox directly.
  # Layouts added in System Settings get replaced on the next
  # switch. IDs are what macOS itself writes when enabling them.
  system.defaults.CustomUserPreferences."com.apple.HIToolbox" = {
    AppleEnabledInputSources =
      map (layout: layout // { InputSourceKind = "Keyboard Layout"; }) [
        {
          "KeyboardLayout ID" = 252;
          "KeyboardLayout Name" = "ABC";
        }
        {
          # Shown as "Ukrainian" in System Settings.
          "KeyboardLayout ID" = -2354;
          "KeyboardLayout Name" = "Ukrainian-PC";
        }
        {
          # Shown as "Russian – PC".
          "KeyboardLayout ID" = 19458;
          "KeyboardLayout Name" = "RussianWin";
        }
      ]
      ++ [
        # Stock Emoji & Symbols viewer entry; keep the input menu item.
        {
          "Bundle ID" = "com.apple.CharacterPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];
  };

  # Keep Touch ID available inside long-running tmux sessions.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
