# Exercise 7: NixOS Test Framework

## About

Probably one of the most impressive features of NixOS, the test framework enables extensive integration testing — and its standout capability is the instantiation of full NixOS virtual machines on the fly, directly from a pure Nix expression, with no external infrastructure required. These VMs boot real NixOS systems, run real services, and can communicate with each other through a virtual network with built-in DNS resolution between nodes.

## Explanation

The test framework is based on a list of virtual machines (called "nodes") that are dynamically instantiated in pure Nix. Each node is a full NixOS system, and they can communicate with each other by hostname thanks to automatic virtual DNS resolution.

```nix
{
  description = "NixOS Test framework example";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    checks.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.testers.runNixOSTest {
      name = "server-client";                 # The test campaign name

      nodes = {                               # The machines (or "nodes")

        server = { pkgs, ... }: {             # A machine named "server"
          # [...< VM configuration >]
        };

        client = { ... }: {                   # A machine named "client"
          # [...< VM configuration >]
        };

        # ...followed by other node definitions

      };

      testScript = ''
        # List of tests to run
      '';
    };
  };
}
```

The easiest way to understand how it all fits together is to follow the comments in [./tests/flake.nix](./tests/flake.nix).

## Launch the test

```bash
cd initiation_nixos/exercices/7-tests-framework/tests

nix flake check -L
```

> ℹ️ The `-L` flag enables verbose logging — you will see the full output of both VMs as they boot and run the test script. It is very verbose by design, so you can follow exactly what is happening at each step.

## Results

The framework is **very** verbose, but you can watch both nodes being instantiated in real time:

```
vm-test-run-serveur-client> client # [   68.005168] systemd[1]: suid-sgid-wrappers.service: Deactivated successfully.
vm-test-run-serveur-client> client # [   68.011694] systemd[1]: Finished Create SUID/SGID Wrappers.
vm-test-run-serveur-client> serveur # [   68.528118] systemd[1]: Starting Update is Completed...
vm-test-run-serveur-client> client # [   68.022101] systemd[1]: Finished Load/Save OS Random Seed.
vm-test-run-serveur-client> client # [   68.024928] systemd[1]: Reached target First Boot Complete.
vm-test-run-serveur-client> client # [   68.033364] systemd[1]: Update Boot Loader Random Seed skipped, no trigger condition checks were met.
[...]
vm-test-run-serveur-client> client # [   72.956380] network-addresses-eth1-start[1130]: adding address 192.168.1.1/24... done
vm-test-run-serveur-client> serveur # [   73.490770] network-addresses-eth1-start[1142]: adding address 192.168.1.2/24... done
vm-test-run-serveur-client> client # [   72.985669] network-addresses-eth1-start[1130]: adding address 2001:db8:1::1/64... done
vm-test-run-serveur-client> serveur # [   73.509954] network-addresses-eth1-start[1142]: adding address 2001:db8:1::2/64... done
vm-test-run-serveur-client> client # [   73.016668] systemd[1]: Finished Address configuration of eth1.
vm-test-run-serveur-client> serveur # [   73.540622] systemd[1]: Finished Address configuration of eth1.
vm-test-run-serveur-client> client # [   73.041381] systemd[1]: Finished Extra networking commands..
```

Then the actual test runs and completes:

```
vm-test-run-serveur-client> serveur # [   74.224621] nginx-pre-start[1221]: nginx: the configuration file /nix/store/26w5i7g43pp7dsbcbq5rgflzji5bf6r4-nginx.conf syntax is ok
vm-test-run-serveur-client> serveur # [   74.229144] nginx-pre-start[1221]: nginx: configuration file /nix/store/26w5i7g43pp7dsbcbq5rgflzji5bf6r4-nginx.conf test is successful
[...]
vm-test-run-serveur-client> serveur: (finished: waiting for unit nginx.service, in 76.20 seconds)
vm-test-run-serveur-client> serveur: waiting for TCP port 80 on localhost
vm-test-run-serveur-client> serveur # Connection to localhost (::1) 80 port [tcp/http] succeeded!
vm-test-run-serveur-client> serveur: (finished: waiting for TCP port 80 on localhost, in 0.16 seconds)
vm-test-run-serveur-client> client: must succeed: curl -f http://serveur/
vm-test-run-serveur-client> client: waiting for the VM to finish booting
vm-test-run-serveur-client> client: Guest shell says: b'Spawning backdoor root shell...\n'
vm-test-run-serveur-client> client: connected to guest root shell
vm-test-run-serveur-client> client: (connecting took 0.00 seconds)
vm-test-run-serveur-client> client: (finished: waiting for the VM to finish booting, in 0.00 seconds)
vm-test-run-serveur-client> client #   % Total    % Received % Xferd  Average Speed   Time    Time    Time  Current
vm-test-run-serveur-client> client #                                   Dload  Upload   Total   Spent   Left  Speed
vm-test-run-serveur-client> client # 100    33  100    33    0     0    368      0 --:--:-- --:--:-- --:--:--  306
vm-test-run-serveur-client> client: (finished: must succeed: curl -f http://serveur/, in 0.28 seconds)
vm-test-run-serveur-client> serveur: making screenshot /nix/store/6ii7pccc44pgwi8c6hm8svmc13zbwabz-vm-test-run-serveur-client/serveur_running.png
vm-test-run-serveur-client> serveur: (finished: making screenshot, in 0.12 seconds)
vm-test-run-serveur-client> ✅ The client has properly reached the server !
```

From here, you can use this framework to build your own test campaigns.