{
  description = "agent-jail base toolchain";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          basePackages = with pkgs; [
            bashInteractive
            binutils
            cacert
            coreutils-full
            curl
            delta
            diffutils
            fd
            findutils
            gawk
            gcc
            gh
            git
            glibc.out
            glibcLocales
            gnumake
            gnugrep
            gnused
            gnutar
            gzip
            jq
            less
            nodejs
            nix
            openssh
            playwright-test
            pkg-config
            pnpm
            poetry
            procps
            python3
            ripgrep
            shadow
            typescript
            uv
            wget
            which
            xz
            yarn
            zsh
          ];
        in
        {
          default = pkgs.buildEnv {
            name = "agent-jail-base";
            paths = basePackages;
            pathsToLink = [ "/bin" "/etc" "/include" "/lib" "/share" ];
          };

          playwright-browsers = pkgs.playwright-driver.browsers.override {
            withFirefox = false;
            withWebkit = false;
          };
        });
    };
}
