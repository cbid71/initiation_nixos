{
  description = "A minimal flake to generate a file in a subdirectory";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.writeTextDir "hello.txt" "Hello! this is a file generated with Nix!";
    };
}