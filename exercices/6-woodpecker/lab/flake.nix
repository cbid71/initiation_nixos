{
  description = "Lab overlay — Gitea + Woodpecker CI on NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.exercice6lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # ── Existing system configuration ──────────────────────────────────
        ./configuration.nix
        # ── The lab ────────────────────────────────────────────────────────
        ./lab.nix
      ];
    };
  };
}