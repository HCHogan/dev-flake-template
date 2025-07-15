{
  description = "My flake template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    rust-overlay,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        packages = with pkgs; [
          cmake
          ninja
          gnumake
          haskell.compiler.ghc912
          haskell.packages.ghc912.haskell-language-server
          cabal-install

          (rust-bin.nightly.latest.default.override
            {
              extensions = [
                "rust-src"
                "rust-analyzer"
                "llvm-tools"
              ];
              # targets = [];
            })
        ];
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import rust-overlay)
          ];
          config = {};
        };
        devShells = {
          default = pkgs.mkShell {
            inherit packages;
          };

          clang = pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} {
            inherit packages;
          };
        };
      };
    };
}
