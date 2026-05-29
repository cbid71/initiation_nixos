# data.nix
# A Nix expression defining a list of records.
[
  {
    id = 1;
    name = "Alice Dupont";
    role = "engineer";
    active = true;
    tags = [ "backend" "rust" "nix" ];
    address = {
      city = "Lyon";
      country = "France";
      postalCode = "69001";
    };
  }
  {
    id = 2;
    name = "Bob Martin";
    role = "designer";
    active = false;
    tags = [ "ui" "figma" "css" ];
    address = {
      city = "Paris";
      country = "France";
      postalCode = "75011";
    };
  }
  {
    id = 3;
    name = "Clara Rossi";
    role = "devops";
    active = true;
    tags = [ "kubernetes" "nix" "ci" ];
    address = {
      city = "Milan";
      country = "Italy";
      postalCode = "20121";
    };
  }
]