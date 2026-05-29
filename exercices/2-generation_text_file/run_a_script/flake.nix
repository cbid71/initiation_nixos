{
  description = "A minimal flake to generate files via a shell script";
  
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "hello-dir";
        src = ./.;
        installPhase = ''
          echo "Hello! this is a file generated with Nix!" > $out/hello.txt
          echo "this is another file" > $out/hello2.txt
        '';
      };
    };
}