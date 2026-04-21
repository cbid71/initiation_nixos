{
  description = "Minimal NixOS qcow2 image";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # ── the NixOS system definition (private, computed here) ───────────────
      myvm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/image/images.nix"  # ← loads the qcow2 image module
          {
            # Minimal system configuration
            nixpkgs.hostPlatform = system;
            system.stateVersion  = "25.05";

            # Your actual config
            services.openssh.enable = true;
            users.users.admin = {
              isNormalUser = true;
              extraGroups  = [ "wheel" ];
              password     = "nixos";
            };
          }
        ];
      };
    in {
      # Using "default" means plain "nix build ." works without specifying an output name.
      packages.${system}.default = myvm.config.system.build.images.qemu;

      # Other available formats — just swap the last attribute:
      #   myvm.config.system.build.images.qemu-efi
      #   myvm.config.system.build.images.iso
      #   myvm.config.system.build.images.amazon
      #   myvm.config.system.build.images.azure
      #   ... see "${nixpkgs}/nixos/modules/image/images.nix" for the full list
    };
}