# Exercise 2: Generate files with Nix

## Generate a simple file

To run the attached script:

```bash
cd generate_file
nix build
```

You get a text file as result:

```bash
ls
flake.lock  flake.nix  result

cat result
Hello ! this is a file generated with Nix !
```

### flake.nix

```nix
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
```

### Analysis

We import nixpkgs to get access to Nix's built-in functions:

```nix
pkgs = import nixpkgs { inherit system; };
```

Then we use `pkgs.writeText` to write a single file:

```nix
packages.${system}.default = pkgs.writeText "hello.txt" "Hello ! this is a file generated with Nix !";
```

`writeText` produces a single file directly — which is why `result` is itself the file and we can `cat` it directly.

---

## Generate a file inside a directory

```bash
cd generate_file_in_directory
nix build
cat result/hello.txt
Hello! this is a file generated with Nix!
```

Notice that this time we use `cat result/hello.txt` instead of `cat result` — because `writeTextDir` produces a **directory** containing the file, whereas `writeText` produced the file itself.

### flake.nix

```nix
{
  description = "A minimal flake to generate a file in a subdirectory";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.writeTextDir "hello.txt" "Hello! this is a file generated with Nix!";
    };
}
```

### Analysis

We use `pkgs.writeTextDir` instead of `pkgs.writeText`. The difference is straightforward:

| Function | Produces |
|---|---|
| `pkgs.writeText "hello.txt" "..."` | a single file |
| `pkgs.writeTextDir "hello.txt" "..."` | a directory containing the file |

---

## Run a script to generate multiple files

When you need more flexibility — multiple files, computed content, shell commands — a derivation using `pkgs.stdenv.mkDerivation` is the right approach.

```bash
cd run_a_script
nix build
ls result
hello2.txt  hello.txt
```

### flake.nix

```nix
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
```

### Analysis

`pkgs.stdenv.mkDerivation` lets you run arbitrary shell commands to produce your output:

- `src` points to the root of our derivation (here, the current directory).
- `installPhase` is a shell script that runs during the build to produce the output files.
- `$out` is a special Nix variable that holds the path of the output directory in `/nix/store/` — everything you write under `$out` ends up in your `result`.

> ℹ️ You do **not** need to create `$out` yourself — Nix creates it for you before `installPhase` runs. Just write your files directly into it.