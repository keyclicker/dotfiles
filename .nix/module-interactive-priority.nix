# Keep the box answering while something big writes to disk.
#
# All guest disks share one slow pool on the Proxmox host. An Android
# SDK fetch into /nix/store once wedged ext4's journal for minutes:
# t3 sat in `jbd2_log_wait_commit`, Tailscale SSH logins hung on
# wtmp. Two levers here: never let a writeback backlog grow big, and
# make heavy writers queue behind the things a human is waiting on.
#
# Not covered: builds agents start from t3 run inside t3.service, so
# they share its priority. Splitting them out needs t3 to launch agents
# in a cgroup of their own.
{ ... }:

let
  # Weights are relative to the default 100.
  interactive = {
    IOWeight = 1000;
    CPUWeight = 1000;
  };
in
{
  # ---- Disk ---------------------------------------------------------

  # IOWeight and ionice classes only mean something under BFQ; the
  # default `none` serves requests strictly in arrival order.
  boot.kernelModules = [ "bfq" ];
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]|vd[a-z]", ATTR{queue/scheduler}="bfq"
  '';

  # Cap dirty page cache at 256M (default: 20% of RAM, ~2G here). Every
  # fsync waits for the journal, and the journal waits for all dirty
  # data queued before it; on this disk 2G takes minutes to drain.
  # Writers now get throttled early instead.
  boot.kernel.sysctl = {
    "vm.dirty_bytes" = 256 * 1024 * 1024;
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;
  };

  # ---- Background: bulk work that may wait --------------------------

  systemd.slices.background = {
    description = "Bulk work that yields to interactive use";
    sliceConfig = {
      IOWeight = 10;
      CPUWeight = 20;
      # Kill the stuck job instead of letting the box thrash.
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };
  };
  systemd.oomd.enable = true;

  # Store downloads and builds touch the disk only when it is idle.
  nix.daemonIOSchedClass = "idle";
  nix.daemonCPUSchedPolicy = "batch";
  systemd.services.nix-daemon.serviceConfig.Slice = "background.slice";

  # Containers land under the same slice (systemd cgroup driver).
  virtualisation.docker.daemon.settings.cgroup-parent = "background.slice";

  # ---- Interactive: what a human waits on ---------------------------

  # tailscaled also hosts Tailscale SSH sessions; journald blocks every
  # service that logs when it stalls.
  systemd.services.sshd.serviceConfig = interactive;
  systemd.services.tailscaled.serviceConfig = interactive;
  systemd.services.systemd-journald.serviceConfig = interactive;
}
