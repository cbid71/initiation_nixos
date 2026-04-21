{
  description = "Data flake — structured list exposed as a flake output";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      # Between "let" and "in", data is private —
      # variables defined here only exist within this block.

      # We use x86_64-linux as our target architecture.
      # nixpkgs.legacyPackages is the standard way to access the package set —
      # despite the name, it is not actually legacy; it is just a historical alias
      # for the full nixpkgs attribute set, kept for compatibility reasons.
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # The important data — imported from a separate file for clarity
      users = [
        ( import ./data.nix )
      ];

      # Serialize the list to a JSON file in the Nix store
      usersJson = pkgs.writeText "users.json"
        (builtins.toJSON users);

      # Serialize to a YAML file via pkgs.runCommand + yq
      usersYaml = pkgs.runCommand "users.yaml" {
        nativeBuildInputs = [ pkgs.yq-go ];
        json = builtins.toJSON users;
        passAsFile = [ "json" ];
      } ''
        yq -P '.' "$jsonPath" > $out
      '';
    in {
      # Inside "in {}", all data is publicly exposed and accessible
      # via "nix eval" or "nix build".

      # ── expose the raw data ──────────────────────────────────────────────
      # Access with:  nix eval .#data.users --json
      data = {
        inherit users;
      };

      # ── expose the store-path artifacts ─────────────────────────────────
      # These expose the /nix/store/ paths of the generated files.
      # Access with:  nix eval .#ourstorepath.usersJson --json
      #               nix eval .#ourstorepath.usersYaml --json
      ourstorepath = {
        inherit usersJson usersYaml;
      };

      # ── expose properly built packages ───────────────────────────────────
      # Using packages.${system} tells Nix these are proper buildable outputs.
      # Build with:   nix build .#usersJson
      #               nix build .#usersYaml
      packages.${system} = {
        inherit usersJson usersYaml;
        default = usersJson;
      };

      # ── a dev shell so you can explore interactively ─────────────────────
      # Enter with:   nix develop
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.nix pkgs.yq-go pkgs.jq ];
        shellHook = ''
          echo ""
          echo "  Useful commands:"
          echo "    nix eval .#data.users --json | jq ."
          echo "    nix build .#usersJson && cat result"
          echo "    nix build .#usersYaml && cat result"
          echo ""
        '';
      };
    };
}