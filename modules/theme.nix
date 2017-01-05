{ config, pkgs, lib, ... }:

with lib;

let
  defaultTheme = (import ./defaultTheme.nix);
in
{
  options.theme = {
    colors = mkOption {
      type = types.attrsOf types.str;
      default = defaultTheme.colors;
    };

    brightness = mkOption {
      type = types.str;
      default = defaultTheme.brightness;
    };

    fontName = mkOption {
      type = types.str;
      default = defaultTheme.fontName;
    };

    termFontName = mkOption {
      type = types.str;
      default = defaultTheme.termFontName;
    };

    fontSize = mkOption {
      type = types.int;
      default = defaultTheme.fontSize;
    };

    gtkTheme = mkOption {
      type = types.str;
      default = defaultTheme.gtkTheme;
    };

    gtkIconTheme = mkOption {
      type = types.str;
      default = defaultTheme.gtkIconTheme;
    };
  };
}
