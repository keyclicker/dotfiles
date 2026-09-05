# T3 Code's `t3` CLI as an npm global (option-npm-globals.nix), the
# home half of module-slopbox.nix: the web server there execs this
# same install, so one `npm install` serves both and neither resolves
# @latest on every start.
{ ... }:

{
  imports = [ ./option-npm-globals.nix ];

  local.npmGlobals.packages = [ "t3" ];
}
