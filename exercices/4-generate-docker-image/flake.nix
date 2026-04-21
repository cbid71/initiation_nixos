{
  description = "Nginx Docker image built with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # ── nginx configuration ────────────────────────────────────────────────
      # nginxConf is a derivation that behaves like a file.
      # It is not written to disk here — it is a pure Nix handle
      # that we will reference later in the image config.
      nginxConf = pkgs.writeText "nginx.conf" ''
        user nobody nobody;
        daemon off;       # critical: keep nginx in foreground so Docker sees it

        events { worker_connections 1024; }

        http {
          include       ${pkgs.nginx}/conf/mime.types;
          default_type  application/octet-stream;

          server {
            listen      8080;
            server_name localhost;
            root        /var/www;
            index       index.html;
          }
        }
      '';

      # ── static content ─────────────────────────────────────────────────────
      # webroot is a derivation that behaves like a directory.
      # Same as above — not on disk yet, just a Nix structure we can copy from.
      webroot = pkgs.runCommand "webroot" {} ''
        mkdir -p $out
        cat > $out/index.html <<EOF
        <!DOCTYPE html>
        <html><body>
          <h1>Hello from Nix-built nginx!</h1>
        </body></html>
        EOF
      '';

    in {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "nginx-nix";
        tag  = "latest";

        # ── equivalent of FROM ────────────────────────────────────────────────
        # In a Dockerfile you would write:  FROM scratch  or  FROM alpine
        # Here there is no "fromImage" attribute, which means we start from
        # scratch — a completely empty base. Nix adds only what we declare.
        # If you wanted an existing base image you would write:
        #
        #   fromImage = pkgs.dockerTools.pullImage {
        #     imageName   = "alpine";
        #     imageDigest = "sha256:...";
        #     sha256      = "...";
        #   };

        # ── equivalent of RUN apt install / COPY ─────────────────────────────
        # Everything listed here is copied into the image as its own layer.
        # Nix handles transitive dependencies automatically — no need to
        # manually install libssl, pcre, zlib, etc.
        contents = [
          pkgs.nginx           # nginx + all its runtime dependencies
          pkgs.coreutils       # ls, cat, mkdir, etc.
          pkgs.bash            # shell (useful for debugging)

          # dockerTools helpers that mimic a real Linux base:
          pkgs.dockerTools.usrBinEnv    # provides /usr/bin/env
          pkgs.dockerTools.binSh        # provides /bin/sh
          pkgs.dockerTools.fakeNss      # provides /etc/passwd and /etc/group
                                        # (required by nginx's "user nobody")
        ];

        # ── equivalent of RUN mkdir / COPY at build time ─────────────────────
        # Shell commands run during the image build, not at container runtime.
        extraCommands = ''
          mkdir -p var/www
          mkdir -p var/log/nginx
          mkdir -p tmp
          cp -r ${webroot}/. var/www/
        '';

        # ── equivalent of ENTRYPOINT / CMD / EXPOSE / ENV ─────────────────────
        config = {
          Entrypoint   = [ "${pkgs.nginx}/bin/nginx" "-c" "${nginxConf}" ];
          ExposedPorts = { "8080/tcp" = {}; };
          Env          = [ "NGINX_PORT=8080" ];
          Labels = {
            "org.opencontainers.image.title"   = "nginx-nix";
            "org.opencontainers.image.source"  = "https://github.com/NixOS/nixpkgs";
          };
        };
      };
    };
}