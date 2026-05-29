{
  description = "Hello world go flake way";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";  # Here we import a very common program in charge of building derivations
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };   # nixpkgs is a native function of Nix in charge of building derivations
    in {
      inherit pkgs;
      packages.${system}.hello-world = pkgs.callPackage ./hello-world.nix {};
    };
}
