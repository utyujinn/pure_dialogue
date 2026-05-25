{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = [ pkgs.gcc pkgs.pkg-config pkgs.sox ];
}
