# Exercise 1: Create your first derivation

## Summary

For this exercise you will have four objectives:
- 1) Install `go` as a package
- 2) Understand why a bare Nix function cannot be built on its own
- 3) Create a simple `hello-world` derivation containing a Go program
- 4) Include this derivation in your full configuration as a NixOS module


## 1) Install Go

Edit `configuration.nix` (or `custom.nix`) and add:

```nix
{
  environment.systemPackages = with pkgs; [
    go
  ];
}
```

Then rebuild:

```bash
nixos-rebuild switch
```

You should now have `go` available:

```bash
go version
go version go1.25.8 linux/amd64
```

And you can run the provided hello-world program:

```bash
go run helloworld/hello-world.go
hello world
```

## 2) Declare hello-world.go in a Nix function

This is the most basic way to incorporate a program into Nix — everything in Nix is a function.

Let's create a file `function_helloworld.nix` anywhere you like:

```nix
{ pkgs }:

pkgs.buildGoModule {
  pname = "hello-world";
  version = "1.0";
  src = "./.";
  goPathPackage = "hello-world/";
}
```

Then let's try to build this function directly:

```bash
nix build ./function_helloworld.nix
```

```
error: path '/home/user/Desktop/initiation_nixos/exercices/1-first-derivation/function_helloworld.nix' is not a flake (because it's not a directory)
```

**You get an error — this is expected.**

This file has two fundamental problems:
- It starts with `{ pkgs }:`, which is a parameter — but `pkgs` is never defined anywhere, so Nix has nothing to inject.
- It cannot be built on its own; it must be called from within a derivation that provides its dependencies.

> ℹ️ You may also notice we use `pkgs.buildGoModule` here, not the older `pkgs.buildGoPackage`. The latter is deprecated — `buildGoModule` is the current recommended function for building Go programs.

## 3) Declare your hello-world derivation

The proper approach is to wrap our Go program in a **derivation** — a self-contained, buildable Nix project. Here is the structure we will use:

```
derivation-hello-world/
├── flake.nix
├── hello-world.nix
└── hello-world.go
```

### flake.nix

`flake.nix` is the entry point of our derivation — think of it as the equivalent of `main.cpp` in C++ or `Main.java` in Java.

A `flake.nix` is built around three important keywords:
- `description` — a human-readable description of the package
- `inputs` — everything needed to build our derivation (programs, libraries, dependencies...)
- `outputs` — what to produce, and how to produce it

In `inputs` we import `nixpkgs`, one of the most important packages in the Nix ecosystem. It contains Nix's native build functions and a vast collection of packages.

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs";
};
```

In `outputs` we do several things. Despite the name, this keyword describes not just the result but the entire build process:
- We receive two variables: `self` (a reserved keyword referring to the current flake) and `nixpkgs` (declared in `inputs`)
- We define two local variables:
  - `system` — the target architecture
  - `pkgs` — the nixpkgs package set specialized for our architecture
- We call our package using `pkgs.callPackage`

```nix
outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    packages.${system}.hello-world = pkgs.callPackage ./hello-world.nix {};
  };
```

> ℹ️ `pkgs.callPackage` automatically injects dependencies into the called function — it provides `pkgs`, but also other variables like `lib` and `stdenv`, without you having to pass them explicitly.

### hello-world.nix

This is the function we started writing in step 2. Now that it is called via `callPackage` from `flake.nix`, the `pkgs` parameter is properly injected.

Using `pkgs.buildGoModule` we tell Nix: "build this Go package for me, for the target architecture."

```nix
{ pkgs }:

pkgs.buildGoModule {
  pname = "hello-world";
  version = "1.0";
  src = ./hello-world;
  postPatch = ''
    go mod init example/hello
  '';

  vendorHash = null;
}
```

### hello-world.go

This is our actual Go program, included in the derivation as the source.

### Building the derivation

With the following command we tell Nix to build the `packages.${system}.hello-world` output from our flake:

```bash
nix build ./derivation-hello-world#hello-world
```

> ⚠️ **A note on naming:** We are using `buildGoModule` to build a package, which itself produces an artifact build from a derivation. Nix and NixOS have overlapping terminology — "module" here refers to the Go module concept, not a NixOS module. Don't let it trip you up.

You should now see a `result` symlink appear:

```bash
[user@nixos:~/Desktop/initiation_nixos/exercices/1-first-derivation]$ ls -l
total 20
drwxr-xr-x 3 user users 4096 26 avril 19:19 derivation-hello-world
-rw-r--r-- 1 user users  129 26 avril 17:53 function_helloworld.nix
drwxr-xr-x 2 user users 4096 26 avril 17:17 helloworld
-rw-r--r-- 1 user users 4566 26 avril 19:29 README.md
lrwxrwxrwx 1 user users   59 26 avril 19:26 result -> /nix/store/9caaxwi8msw5rywyxz8b6ak044r1dk0x-hello-world-1.0
```

Your build is complete — a directory in `/nix/store/` named `hello-world-1.0`.

Let's run it:

```bash
result/bin/hello-world
hello world !
```

You can also run it directly without the symlink:

```bash
nix run ./derivation-hello-world#hello-world
hello world
```

## 4) Include this program in your full configuration

We have our build result in the Nix store:

```bash
ls -l result
lrwxrwxrwx 1 user users 59 26 avril 19:46 result -> /nix/store/x2yj4nplmcpm0v59s82r3lsk12xfx8wr-hello-world-1.0
```

To make this program available system-wide, edit `/etc/nixos/configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  (pkgs.callPackage /home/user/Desktop/initiation_nixos/exercices/1-first-derivation/derivation-hello-world/hello-world.nix {})
];
```

Then rebuild:

```bash
nixos-rebuild switch
```

`hello-world` should now be available as a system command.