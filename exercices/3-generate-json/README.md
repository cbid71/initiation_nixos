# Exercise 3: Generate JSON and YAML from Nix variables

## Explanations

We learned earlier that `flake.nix` is the entry point of a Nix project — its `main()`. It is divided into three parts:

```nix
{
  description = "";
  inputs = {};
  outputs = {};
}
```

The **description** part is just a human-readable label:

```nix
description = "my great program";
```

The **inputs** part declares the dependencies of the project. One of the most common is `nixpkgs`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};
```

The **outputs** part contains the logic of the flake and exposes its results: data, packages, dev shells, and more.

The function `{ self, nixpkgs }` receives what was declared in `inputs` — every input variable must be listed here to be usable. `self` is a reserved keyword that refers to the current flake itself.

```nix
outputs = { self, nixpkgs }: {
  packages     # ← Nix CLI knows this one → nix build
  devShells    # ← Nix CLI knows this one → nix develop
  apps         # ← Nix CLI knows this one → nix run
  checks       # ← Nix CLI knows this one → nix flake check
  overlays     # ← Nix CLI knows this one → consumed by other flakes
  nixosModules # ← Nix CLI knows this one → consumed by nixosConfigurations
  formatter    # ← Nix CLI knows this one → nix fmt
  blablabla    # ← Nix CLI has no idea   → warns "unknown output", but still usable as a variable
}
```

Since `outputs` is meant to expose public data, it can be split into a private section and a public section using `let ... in`:

```nix
outputs = { self, nixpkgs }:
  let
    # private — variables defined here are only visible within this block
  in {
    # public — anything here is exposed and accessible via nix eval / nix build
  };
```

In practice:
- The `let` block is used to import modules, invoke derivations, and prepare data.
- The `in { }` block is used to format and expose that data publicly.

In this exercise, `users` is computed privately in `let`, then `usersJson` and `usersYaml` are derived from it — also privately — before being exposed in `packages.${system}`.

---

## Run the program

```bash
nix eval .#data.users --json          # inspect the raw user list
nix eval .#ourstorepath --json        # inspect the store paths
nix eval .#ourstorepath.usersJson --json  # returns the /nix/store/ path of users.json
nix build .#usersJson                 # produces a JSON file as result
nix build .#usersYaml                 # produces a YAML file as result
```

> ℹ️ **Bonus:** You can also evaluate `data.nix` standalone, without building the full flake:
> ```bash
> nix eval --json --file data.nix       # prints the Nix data as JSON
> nix eval --json --file data.nix | yq -P  # converts it to YAML
> `