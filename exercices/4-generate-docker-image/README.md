# Exercise 4: Create a Docker image

## Introduction

In this exercise, we will create a Docker image **without writing a Dockerfile**. Instead, we declare the entire image in Nix using `dockerTools.buildLayeredImage`, which both defines and builds the image in a single step.

Please read the comments in `flake.nix` carefully before running the build — they map each Nix construct to its Dockerfile equivalent.

## Commands

```bash
nix build .
docker load < result
docker run --rm -p 8080:8080 nginx-nix:latest
curl http://localhost:8080
```

## Explanation

The `flake.nix` follows the same structure as previous exercises:
- `inputs` for dependencies
- `outputs` for the logic, split into:
  - `let ... in` for the private part
  - `in { }` for the public part

### Private section — `let ... in`

In the private section we declare two variables:

- `nginxConf` — a derivation that behaves like a file (an nginx configuration file)
- `webroot` — a derivation that behaves like a directory (the static website content)

> ℹ️ These derivations are declared between `let` and `in`, so they are **pure Nix structures** — they are never actually written to disk at this stage. They act as file-like and directory-like handles that can be referenced and copied later during the image build.

### Public section — `packages.${system}.default`

We invoke `pkgs.dockerTools.buildLayeredImage` through `packages.${system}.default`, just like in previous exercises. Using the `default` keyword means we can run `nix build .` without specifying an output name.

`buildLayeredImage` produces a **layered** Docker image — each dependency gets its own layer. This is better than a flat image because Docker can cache and reuse individual layers, making subsequent builds and pulls significantly faster.