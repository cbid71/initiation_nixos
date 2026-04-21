{ pkgs }:

pkgs.buildGoModule {
  pname = "hello-world";
  version = "1.0";
  src = "./.";
  goPathPackage = "hello-world/";
}