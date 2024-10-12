{
	description = "Flake for Odin Development in Nix";

	inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    odin-overlay.url = "github:kilzm/odin-overlay";
  };

  outputs = { nixpkgs, odin-overlay, ... }:
	  let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      odin-pkgs = odin-overlay.outputs.packages.${system};
    in {
      devShells.${system}.default = with odin-pkgs; pkgs.mkShell {
        nativeBuildInputs = [ odin-latest ols ];
        ODIN_PATH = "${odin-latest}";
      };
    };
}
