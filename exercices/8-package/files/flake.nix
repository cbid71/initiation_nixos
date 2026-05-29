{
  description = "hello-nix — a small tkinter demo app for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in {
      # The package itself — callable via "nix build" or "nix profile install"
      packages.${system}.default = pkgs.callPackage ./default.nix {};

      # Allows "nix run" to launch the app directly
      apps.${system}.default = {
        type    = "app";
        program = "${self.packages.${system}.default}/bin/hello-nix";
      };

      # Dev shell: python3 with tkinter available for interactive development
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.python3 ];
      };
    };
}