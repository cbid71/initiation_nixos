{
  description = "A minimal flake to generate a file";
  
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.writeText "hello.txt" "Hello ! this is a file generated with Nix !";
    };
}