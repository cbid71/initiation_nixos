# From configuration.nix to flake.nix

The modern way of managing NixOS is to manage everything through a `flake.nix` file.

The most central file of nixOs configuration for the user is `/etc/nixos/configuration.nix` but you can convert it to flake.nix


Edit `/etc/nixos/configuration.nix`

```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then

```
nixos-rebuild switch
```

Then

```
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration_origin.nix
sudo nano /etc/nixos/flake.nix
```

then in `/etc/nixos/flake.nix`

```
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.mypc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        /etc/nixos/configuration_origin.nix
      ];
    };
  };
}
```

Then

```
sudo nixos-rebuild switch --flake /etc/nixos#mypc
```
