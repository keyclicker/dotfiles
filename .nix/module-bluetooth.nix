# Bluetooth with blueman's tray applet. Inert in a VM with no
# adapter; here for the bare-metal desktop that composes the same
# stack.
{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;
}
