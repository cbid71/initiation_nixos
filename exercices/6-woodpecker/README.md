# Exercise 6: Woodpecker CI

## Introduction

An example of Woodpecker CI integrated with Gitea (a self-hosted Git service similar to GitLab).

## Disclaimer

> ⚠️ We strongly advise you to run this lab on a testing virtual machine, since we are modifying `configuration.nix`.

## Architecture

```
| Woodpecker | <──── OAuth2 ────> | Gitea |
      |                                |
      └──────> | PostgreSQL | <────────┘
```

```
~/lab/
├── flake.nix          # imports your /etc/nixos config and adds the lab module
├── lab.nix            # Gitea + Woodpecker + PostgreSQL only
└── README.md
```

## Services & ports

| Service          | URL                       |
|------------------|---------------------------|
| Gitea            | http://localhost:3000      |
| Woodpecker UI    | http://localhost:8000      |
| PostgreSQL       | socket /run/postgresql     |
| Agent ↔ Server   | localhost:9000 (internal)  |

## Deploy

As we saw earlier, the flake approach is the recommended way to manage NixOS for better reproducibility and flexibility. Our existing system configuration still lives in `/etc/nixos/configuration.nix`, so in this exercise we install the lab as an additional module layered on top of it.

```bash
cp -R lab/ ~/
cp /etc/nixos/*.nix ~/lab/.
sudo nixos-rebuild switch --flake .#exercice6lab
```

This will:
- import your existing `/etc/nixos/configuration.nix`
- install all the lab services on top of it

---

## Post-installation steps

### 1. Create the Gitea admin account

Open http://localhost:3000 and create an account with:
- username: `admin` (must match `WOODPECKER_ADMIN` in `lab.nix`)
- password: `changeme`

### 2. Add the Woodpecker OAuth2 application in Gitea

This allows Woodpecker to authenticate users via Gitea.

Go to: `Site Administration` → `Integrations` → `Applications` → `OAuth2 Applications` → `Add`

- Application Name: `Woodpecker CI`
- Redirect URI: `http://localhost:8000/authorize`

Save and keep note of the `Client ID` and `Client Secret` that Gitea generates.

### 3. Fill in the secrets in lab.nix

```nix
wpOauthClientId     = "<client-id>";
wpOauthClientSecret = "<client-secret>";
```

Then reapply the configuration:

```bash
sudo nixos-rebuild switch --flake .#exercice6lab
```

### 4. Connect to Woodpecker

Open http://localhost:8000 → Login with Gitea → Authorize.

---

## Run a pipeline

Add a `.woodpecker.yml` file to any repository activated in Woodpecker:

```yaml
steps:
  - name: build
    image: alpine
    commands:
      - echo "Hello from Woodpecker!"
```

Enable the repository in Woodpecker, then push — the pipeline will be triggered automatically.

---

## Uninstall the lab

Remove or comment out the `./lab.nix` module in `flake.nix`, then rebuild:

```bash
sudo nixos-rebuild switch --flake .#exercice6lab
```

Then remove the persistent data directories:
- `/var/lib/gitea`
- `/var/lib/postgresql`
