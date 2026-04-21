# Exercise 5: Generate a virtual machine image

## Introduction

Associated documentation:
[https://nixos.org/manual/nixos/stable/#sec-image-nixos-rebuild-build-image](https://nixos.org/manual/nixos/stable/#sec-image-nixos-rebuild-build-image)

Until recently, `nixos-generators` was the most widely used tool to generate NixOS images. With its deprecation in April 2026, we now use its underlying tool directly: `nixpkgs.lib.nixosSystem`.

It allows us to create a ready-to-use NixOS image in various formats (QCOW2, ISO, Amazon, Azure, and more).

## Explanation

As usual, we have the same flake structure:

```nix
{
  description = "";
  inputs = {};
  outputs = {
    let
      # private
    in {
      # public
    }
  };
}
```

We use `nixpkgs.lib.nixosSystem` (previously best known through its wrapper `nixos-generators`) to generate our image. Here is where it sits in the nixpkgs tree:

```
nixpkgs
├── lib                          ← pure Nix functions, no system needed
│     └── nixosSystem            ← what we use here to generate our image
└── legacyPackages
      └── x86_64-linux           ← pkgs, the full package set (not actually legacy)
            ├── nginx
            ├── python3
            └── ...
```

Note that `lib.nixosSystem` lives under `nixpkgs.lib`, not under `legacyPackages` — it is system-independent and does not need an architecture to be selected first.

The `packages.${system}` keyword at the root of the public `in {}` block is a well-known flake output convention that the Nix CLI recognizes. We already saw it in exercise 3 — it acts as "the root" of your build target in `nix build .`.

## Generate the image

```bash
nix build .
# This will take a long time on first run since all dependencies are downloaded.
# Once complete, your QCOW2 image is available here:
ls result/
nixos-image-qcow2-25.05.20260102.ac62194-x86_64-linux.qcow2
```

- It will ask for a login — use `admin` / `nixos` as defined in the flake.
- If it hangs at boot, try adding `-serial mon:stdio` to your QEMU command.
