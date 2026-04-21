# Tutorial NixOS

> ⚠️ **Work in progress**

![nixos_logo.png](./pictures/nixos_logo.png)

## Introduction

Welcome to the world of NixOS. In this tutorial we will learn everything from scratch — from the initial configuration of a brand new machine to more advanced usage such as describing a whole project declaratively.

Keep in mind that NixOS is still a very dynamic project, rapidly evolving. Many ways of doing the same thing exist, and some approaches may become legacy or deprecated within a few months. We will do our best to show you a simple and current path.

Nix and NixOS can be hard to understand and frustrating at first, but don't worry — frustration is part of this game. Take a deep breath and enjoy!

## What are Nix and NixOS?

Nix is both a cross-platform package manager created by Eelco Dolstra in 2003, designed for Unix-like operating systems, and a functional language used to configure those systems. Its key characteristic is that it installs each software package in a unique directory with immutable content, then generates symbolic links in the expected locations.

NixOS is a Linux distribution built from scratch around the Nix package manager, originally created as a research project and now widely used for its reproducibility.

## Get NixOS

[NixOS official website](https://nixos.org/download/#nix-more)

For this course, we will work on NixOS, the dedicated operating system that natively uses Nix as both a reproducible configuration manager and a package manager.

Our environment will be a **virtual machine running NixOS 25.11**, deployed on a virtualization engine such as QEMU or VirtualBox. Your first step should be to install NixOS on a VM.

## How to navigate the documentation?

NixOS is notoriously known for having a steep learning curve. The following links will help you improve your knowledge:

- Practice NixOS: [nix.dev](https://nix.dev/)
- Official NixOS documentation: [https://nixos.org/learn](https://nixos.org/learn/)
- Official NixOS Wiki: [https://wiki.nixos.org/wiki](https://wiki.nixos.org/wiki/)
- Official NixOS GitHub: [https://github.com/NixOS](https://github.com/NixOS)
- NixPKGS GitHub: [https://github.com/NixOS/nixpkgs/tree/master/pkgs](https://github.com/NixOS/nixpkgs/tree/master/pkgs)

## Installing packages

Let's assume you are logged into your VM running NixOS. One of the first things to check is the ability to install a package. For this example we will install a simple tool: `git`.

Like any other distribution, NixOS has its own official repository and a repository browser showing the current stable version and the unstable one: [NixOS Search Package](https://search.nixos.org/packages?channel=25.11).

### Command-line (temporary)

This approach is recommended for testing. It spawns a shell with the requested program available.

> ℹ️ **Note:** Two syntaxes exist for this, and they are not interchangeable:
>
> | Old CLI | New CLI |
> |---|---|
> | `nix-shell -p cowsay` | `nix shell nixpkgs#cowsay` |
>
> **`nix-shell -p`** is the legacy command, built around the `-p` flag from the start.
>
> **`nix shell`** is part of the modern unified Nix 2.0 CLI (`nix build`, `nix run`, `nix develop`...). It does **not** accept a `-p` flag — instead it expects a full package reference in the form `nixpkgs#<package>`, meaning "the `cowsay` attribute from the `nixpkgs` flake." Running `nix shell -p cowsay` will produce:
> ```
> error: unrecognised flag '-p'
> ```
>
> Both commands are valid and coexist — you will see both in the wild. This tutorial uses the modern form.

```bash
# Modern
nix shell nixpkgs#<package_name>

# Legacy (still works, widely found in older docs)
nix-shell -p <package_name>
```

![git_command_line_installation](./pictures/git_command_line_installation.png)

Pay attention to the prompt change during these commands:

```bash
[user@nixos:~]$ cowsay hello
bash: cowsay: command not found

[user@nixos:~]$ nix shell nixpkgs#cowsay
this path will be fetched (0.01 MiB download, 0.05 MiB unpacked):
  /nix/store/gx2whfvcahb2ba9gmwgnvflgn8jclqxd-cowsay-3.8.4
copying path '/nix/store/gx2whfvcahb2ba9gmwgnvflgn8jclqxd-cowsay-3.8.4' from 'https://cache.nixos.org'...

[nix-shell:~]$ cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

Once you leave the shell, the command is no longer available:

```bash
[nix-shell:~]$ exit
exit

[user@nixos:~]$ cowsay hello
bash: cowsay: command not found
```

You can install it into your profile to make it persist across sessions:

```bash
[user@nixos:~]$ nix profile add nixpkgs#cowsay

[user@nixos:~]$ which cowsay
/home/user/.nix-profile/bin/cowsay

[user@nixos:~]$ cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

You can also declare a `shell.nix` file to create your own lightweight environment:

```nix
# shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.nodejs
    pkgs.git
    pkgs.cowsay
  ];
}
```

Then run `nix-shell` to get a session with Python 3, Node.js, Git and cowsay available:

> ℹ️ Here we use `nix-shell` (no `-p` flag) to load a `shell.nix` file — this is different from `nix shell nixpkgs#package`. The modern equivalent for file-based dev shells is `nix develop` with a `flake.nix`, covered just below.

```bash
[user@nixos:~/Downloads]$ nix-shell
this path will be fetched (0.01 MiB download, 0.05 MiB unpacked):
  /nix/store/8qyi4myzjix4xwy1gnfw06bz9xl9zzxn-cowsay-3.8.4
copying path '/nix/store/8qyi4myzjix4xwy1gnfw06bz9xl9zzxn-cowsay-3.8.4' from 'https://cache.nixos.org'...

[nix-shell:~/Downloads]$ cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

[nix-shell:~/Downloads]$ git --version
git version 2.51.2

[nix-shell:~/Downloads]$ exit
```

> ℹ️ Keep in mind that `mkShell` never permanently installs tools — everything is scoped to the shell session.

You can also go the modern route and use a flake file. The file must be named `flake.nix`:

```nix
{
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = [
            pkgs.go
            pkgs.git
            pkgs.nodejs
        ];
      };
    };
}
```

Then enter the shell with `nix develop` instead of `nix-shell`:

```bash
[user@nixos:~/Downloads/lab]$ nix develop
warning: creating lock file "/home/user/Downloads/lab/flake.lock":
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/3d8f0f3f72a6cd4d93d0ad13203f2ea1cb7e1456?narHash=sha256-q%2BfF42iv/geEbHfgSzy3tS0FF/EyD6XTZ98E6yxiBO8%3D' (2026-05-23)

[user@nixos:~/Downloads/lab]$ node
Welcome to Node.js v24.15.0.
Type ".help" for more information.
>
```

### Configuration file (declarative, recommended)

The declarative approach via a configuration file is the recommended way to manage your system.

NixOS stores its configuration in `/etc/nixos/configuration.nix`. This is the entry point for the system configuration of a machine — think of it as the `main` file of your system definition.

Let's take a look at `/etc/nixos/configuration.nix`. It contains settings for boot, networking, hostname, keymap, and more. Here is an extract of a default NixOS configuration file:

```bash
cat /etc/nixos/configuration.nix
```

```nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";

[...]
```

To keep our customizations clean, we will create a separate file and include it in `configuration.nix`. The name doesn't matter; we'll call it `custom.nix`:

```bash
touch /etc/nixos/custom.nix
```

Then edit `configuration.nix` to include it:

```bash
nano /etc/nixos/configuration.nix
```

```nix
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./custom.nix   # <-------- ADD THIS LINE
    ];
```

Now let's install a package declaratively. Edit `custom.nix`:

```nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
  ];
}
```

What does this file say?

- `{ config, lib, pkgs, ... }:` declares the module parameters — we will cover these in detail later.
- `environment.systemPackages` declares packages to install at system level, available to all users.
- `with pkgs;` brings the `pkgs` attribute set into scope so you can reference packages by name directly.
- `git` is the package we want to install.

Now apply the configuration:

```bash
nixos-rebuild switch
```

```
building the system configuration...
updating GRUB 2 menu...
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
[...]
Done. The new configuration is /nix/store/c9yysj2p93h4rq9sjidk8i3qn0pi2shi-nixos-system-nixos-25.11.9418.c7f47036d3df
```

`git` should now be available:

```bash
git -v
git version 2.51.2
```

## Installing and managing Home Manager

So far we have only looked at system-level configuration managed by an administrator. It can be very useful to allow users to configure their own home environment the Nix way. The `home-manager` package makes it easy to manage per-user configuration declaratively.

[Official wiki for Home Manager](https://wiki.nixos.org/wiki/Home_Manager)

There are two main installation modes for Home Manager:

- **Standalone mode** — gives the user access to a `home-manager` CLI to manage their own configuration under `$HOME`.
- **Module mode** — more reproducible and centralized; Home Manager is managed directly as part of the NixOS configuration.

There are two places where you can declare the Home Manager installation:
- `/etc/nixos/configuration.nix` or an included sub-file
- `/etc/nixos/flake.nix` (the more modern approach, covered later)

> ⚠️ There is an existing package called `home-manager` that can be installed as a standalone tool via `systemPackages` (giving access to a `homectl` CLI), but since it is not officially documented or recommended, we will not cover it here.

**For this tutorial we will use the most documented approach:**
- Install `home-manager` as a NixOS module
- Declare the installation in our `custom.nix` sub-file, which is included in `configuration.nix`

Assuming our user's username is `user`:

```nix
{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz;
  username = "user";
in
{
  imports =
    [
      (import "${home-manager}/nixos")
    ];

  home-manager.users.${username} = { pkgs, ... }: {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.11";
  };
}
```

Then rebuild the configuration:

```bash
nixos-rebuild switch
```

Verify the installation:

```bash
home-manager --version
25.11-pre
```

## Packages, functions, and derivations

When you think of a package, you probably picture a binary or a directory full of libraries — but that's not how Nix sees it. In Nix, a **package** is a **function written in the Nix language** that returns a **derivation**. A derivation is a recipe that goes through a *builder* to produce a result stored in `/nix/store/`. Nix usually hides this recipe from you and directly serves you the build result.

Here is what a package looks like in Nix:

```nix
# A package in Nix
{ stdenv, fetchurl, zlib }:   # ← its dependencies

stdenv.mkDerivation {         # ← returns a derivation
  name = "mysoftware-1.0";
  src  = fetchurl { ... };
  buildInputs = [ zlib ];
}
```

Here is another example: a derivation that builds a simple *hello* program with an optional `name` parameter:

```nix
# hello.nix
{ stdenv, name ? "World" }:   # ← optional parameter with default value

stdenv.mkDerivation {
  name = "hello-nix";

  src = builtins.toFile "hello.c" ''
    #include <stdio.h>
    int main() {
      printf("Hello, ${name}!\n");
      return 0;
    }
  '';

  unpackPhase = ''
    cp $src hello.c
  '';

  buildPhase = ''
    gcc hello.c -o hello
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin/hello
  '';
}
```

Build and run it:

```bash
nix-build hello.nix
./result/bin/hello
# Hello, World!
```

On more evolved projects, you will typically chain packages together. To do this, you use `callPackage`, which automatically resolves and injects a package's dependencies.

```nix
# default.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./hello.nix { name = "Alice"; }
```

Build and run:

```bash
nix-build && ./result/bin/hello
# Hello, Alice!
```

## Introducing flakes

Until now we have made changes either through `nix shell` / `nix-shell` or by modifying `configuration.nix`. The more modern approach is to use a **flake project** — a self-contained, reproducible unit with pinned dependencies.

A flake project has one mandatory file, but typically follows a conventional structure:

```
myproject/
   |-- flake.nix        # mandatory — entry point
   |-- flake.lock       # auto-generated — pins dependency versions
   |-- README.md        # optional — still a good idea
   |-- default.nix      # optional — legacy compatibility
   |-- nixos/           # optional — for NixOS system configuration
   |     |-- configuration.nix
   |     |-- ...
   |-- modules/         # optional — reusable NixOS modules
   |-- packages/        # optional — custom Nix packages
   |     |-- default.nix
   |     |-- ...
   |-- overlays/        # optional — to customize or override packages
         |-- ...
```

Flake projects are the foundation for creating your own Nix packages, generating resources, and encapsulating custom programs — all of which we will explore later in this tutorial.

## Nix packages, modules, and derivations

One of Nix's greatest strengths is the concept of **derivation**. At its core, Nix stores packages in unique, immutable directories under `/nix/store/<package>-<version>/`, then references them via symbolic links in their expected locations. This makes it easy to maintain multiple versions of the same package side by side.

Each directory in the store is called an **artifact build** — the result of a `nixos-rebuild switch` command, produced by evaluating a Nix derivation. A derivation is the *recipe* that describes how to build a package.

**When Nix builds a program**, it first evaluates the package expression to generate a **derivation file**, stored at `/nix/store/****.drv`. This file describes everything Nix needs to build or reproduce the package: source URL, dependencies, build steps, expected output paths, and more.

**A module** is the piece of Nix code that includes a derivation into your overall system configuration.

In summary:
- There is one derivation per package per version.
- A new derivation is created for each new version of a package.
- You include a package in your system configuration through a **module**.

![several versions](./pictures/several_versions.png)

## Ex 0: Avoid a saturated disk — remove obsolete packages

Nix tends to accumulate packages in `/nix/store` over time. It is good practice to regularly clean up unused packages with:

```bash
nix-collect-garbage
```

```
finding garbage collector roots...
deleting garbage...
deleting unused links...
[...]
deleting '/nix/store/9rq2ab2wl3ia1ism6zjvdxcnpv9s9rgn-add-hardening.sh'
deleting '/nix/store/z9lcay2wddgsbf2nqxc7r53a48nq5qib-source.drv'
deleting '/nix/store/7q10lq3gf9mi253p267zh13hv7c94m1g-machine.py'
deleting '/nix/store/cqnaz62zg9lbipxr9fg8d9ig48s8f4xc-source.drv'
deleting '/nix/store/g4b55ykz4l3990dvbsn6bass3dkzr4zj-Test-RequiresInternet-0.05.tar.gz.drv'
deleting '/nix/store/8chcijblwbvhcd5jnxapfdr7wjcp96zp-Module-Build-0.4234.tar.gz.drv'
deleting '/nix/store/124gfdn3yd6frjaxcpw1jlj2580alxrf-Capture-Tiny-0.48.tar.gz.drv'
deleting unused links...
note: currently hard linking saves -0.00 MiB
6530 store paths deleted, 6172.93 MiB freed
```

## Ex 1: Creating your first derivation

Follow: [Exercise 1](./exercices/1-first-derivation/)

## Ex 2: Generate files with Nix

Follow: [Exercise 2](./exercices/2-generation_text_file/)

## Ex 3: Generate a JSON file from a Nix attribute set

Follow: [Exercise 3](./exercices/3-generate-json/)

## Ex 4: Create a Docker image

Follow: [Exercise 4](./exercices/4-generate-docker-image/)

## Ex 5: Create a virtual machine image (QCOW2)

The tool `nixos-generators` is by far the main tool for generating OS images from scratch. It was recently moved (end of January 2026).

Follow: [Exercise 5](./exercices/5-generate-image/)

## Ex 6: CI/CD integration with Woodpecker

Woodpecker is not tied to NixOS specifically — this exercise illustrates how NixOS can be integrated into a CI/CD pipeline in a professional environment.

Follow: [Exercise 6](./exercices/6-woodpecker/)

## About CI/CD

The community maintains an [awesome-nix list](https://github.com/nix-community/awesome-nix) of mature projects covering various aspects of Nix, including fleet management. Tools like [NixFleet](https://discourse.nixos.org/t/nixfleet-declarative-nixos-fleet-management-with-signed-gitops/77195/4) are also emerging.

That said, as of late May 2026, there is no officially maintained CI/CD tool for managing a fleet of NixOS machines. Several community tools are working to fill this gap.

## Ex 7: Test framework

Follow: [Exercise 7](./exercices/7-tests-framework/)

## Ex 8: Building a package

Follow: [Exercise 8](./exercices/8-package/)

## Bonuses

- Examples of hardened NixOS: [Securix and Bureautix](./initiation_nixos/Bonus/securix-and-bureautix/)
- Migrating [from configuration.nix to flake.nix](./initiation_nixos/Bonus/from_configuration.nix_to_flake.nix)