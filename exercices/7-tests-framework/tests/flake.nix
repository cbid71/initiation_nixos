{
  description = "NixOS Test framework example";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    checks.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.testers.runNixOSTest {
      name = "serveur-client";               # The test campaign name

      nodes = {                              # The machines (or "nodes")

        serveur = { pkgs, ... }: {           # Named "serveur" (French) so it stands out clearly in logs
          virtualisation.memorySize = 256;
          virtualisation.cores = 1;
          documentation.enable = false;
          services.nginx = {
            enable = true;
            virtualHosts."serveur" = {
              root = pkgs.writeTextDir "index.html" ''
                <h1>Hello from NixOS 🐧</h1>
              '';
            };
          };
          networking.firewall.allowedTCPPorts = [ 80 ];
        };

        client = { ... }: {                  # A minimal client node — no services needed
          virtualisation.memorySize = 256;
          virtualisation.cores = 1;
          documentation.enable = false;
        };

      };

      testScript = ''
        # Boot all nodes
        start_all()

        # Server side: wait for nginx to be up and listening
        serveur.wait_for_unit("nginx.service")
        serveur.wait_for_open_port(80)

        # Client side: send an HTTP request to the server
        # Note: "serveur" is a valid hostname in the test framework's virtual DNS
        client.succeed("curl -f http://serveur/")

        # Server side: capture a screenshot of the running server
        serveur.screenshot("serveur_running")

        # If we reach this line, all tests above have passed
        print("✅ The client has properly reached the server !")
      '';
    };
  };
}