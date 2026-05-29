# Installation of Securix/Bureautix


Github organization related : [https://github.com/cloud-gouv](https://github.com/cloud-gouv)

Securix is an hardened variation of NixOS maintain by the Direction Interministérielle du Numérique (DINUM) a french public IT department that aims to use NixOS as a main OS for desktop on State level. It's based on requirements of ANSSI ( National Agency for the Security of IT ).

Bureautix is a ready-to-use implementation of Securix.

The installation itself is using a dependencies management tool `npins`

```
git clone https://github.com/cloud-gouv/bureautix-example.git
cd bureautix-example/

nix-shell -p npins

npins init

nix-build -A net-installer  # to generate an image via a network boot
# OR 
nix-build -A usb-installer  # to generate an image for a USB key
```

The project is still is alpha so it might break.

During the writing of this part the generation was still too young to serve as mature example so we decide to put it more as a nice project to follow.
