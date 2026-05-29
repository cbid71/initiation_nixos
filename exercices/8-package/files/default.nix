{ lib, python3, imagemagick, makeWrapper }:
let
  # Python with tkinter included
  python = python3.withPackages (ps: [ ps.tkinter ]);
in
python.pkgs.buildPythonApplication {
  pname = "hello-nix";
  version = "0.1.0";

  # Source: this directory
  src = ./.;

  # No external Python dependencies
  dependencies = [];

  # We need imagemagick to convert the SVG icon, and makeWrapper to wrap the binary
  nativeBuildInputs = [ imagemagick makeWrapper ];

  # No standard Python build phase (no setup.py / pyproject.toml)
  format = "other";

  installPhase = ''
    # ── Binary ──────────────────────────────────────────────────────────────
    mkdir -p $out/bin $out/libexec
    cp hello.py $out/libexec/hello.py
    makeWrapper ${python}/bin/python3 $out/bin/hello-nix \
      --add-flags "$out/libexec/hello.py"

    # ── Icon ────────────────────────────────────────────────────────────────
    mkdir -p $out/share/icons/hicolor/128x128/apps
    convert ${./icon.svg} -resize 128x128 \
      $out/share/icons/hicolor/128x128/apps/hello-nix.png

    # ── Desktop entry ───────────────────────────────────────────────────────
    mkdir -p $out/share/applications
    substitute ${./hello-nix.desktop} $out/share/applications/hello-nix.desktop \
      --replace "Icon=hello-nix" \
                "Icon=$out/share/icons/hicolor/128x128/apps/hello-nix.png"
  '';

  meta = with lib; {
    description = "Small tkinter demo app for NixOS";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hello-nix";
  };
}