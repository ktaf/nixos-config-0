# see https://github.com/jimdigriz/debian-mssp4 for details on surface pro 4
# https://gitlab.com/jimdigriz/linux.git (mssp4 branch)
# More recent: https://github.com/jakeday/linux-surface
# https://github.com/Shadoukun/linux-surface-ipts

{ config, lib, pkgs, ... }:

let
  version = "4.19.37";
  patchlevel = "1";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = lib.concatStrings (lib.intersperse "." (lib.take 3 (lib.splitString "." "${version}.0")));
  # branchVersion needs to be x.y
  branchVersion = lib.concatStrings (lib.intersperse "." (lib.take 2 (lib.splitString "." version)));

  linux-surface = pkgs.fetchFromGitHub {
    owner = "jakeday";
    repo = "linux-surface";
    rev = "${version}-${patchlevel}";
    sha256 = "1q8dv7j6gwgszqavb35aswwfn7c7mwkc2xqd2v8gvxnjk7sp4747";
  };

  buildFirmware = (name: subdir: src: pkgs.stdenvNoCC.mkDerivation {
    name = "${name}-firmware";
    src = src;
    nativeBuildInputs = [ pkgs.unzip ];
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/lib/firmware/${subdir}
      cp -r * $out/lib/firmware/${subdir}
    '';
  });

  # TODO: Parameterize for all the surface pro revisions.
  i915-firmware = buildFirmware "i915" "i915" "${linux-surface}/firmware/i915_firmware_skl.zip";

  ipts-firmware = buildFirmware "ipts" "intel/ipts" "${linux-surface}/firmware/ipts_firmware_v78.zip";

  mwifiex-firmware = buildFirmware "mwifiex" "mrvl" (pkgs.fetchFromGitHub {
    owner = "jakeday";
    repo = "mwifiex-firmware";
    rev = "63ca64a73c05fa5bcceb687422cbc28185bb6355";
    sha256 = "11yia5pglmkahkjbihsq1s4pq6caw6l11ni8s48i94yz272nfinq";
  } + /mrvl);
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest.extend (self: super: {
      kernel = super.kernel.override { argsOverride = rec {
        inherit version modDirVersion;
        extraMeta.branch = branchVersion;

        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
          sha256 = "0xjycbjlzpgskqnwcjml60vkbg7x8fsijdj6ypmhpry7q8ii677a";
        };
      };};
    });

    kernelPatches = (map (name: { name=name; patch="${linux-surface}/patches/${branchVersion}/${name}.patch";})
      [ "0001-surface-acpi" "0002-suspend" "0003-buttons" "0004-cameras" "0005-ipts" "0006-hid" "0007-sdcard-reader" "0008-wifi" "0009-surface-power" "0010-surface-dock" "0011-mwlwifi" "0012-surface-lte" ]);

    initrd.kernelModules = [ "hid-multitouch" ];
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" "hid-multitouch" ];
  };

  hardware.firmware = [ pkgs.firmwareLinuxNonfree i915-firmware ipts-firmware mwifiex-firmware ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DEVPATH=="*/0000:0?:??.?", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"

    # handle typing cover disconnects
    # https://www.reddit.com/r/SurfaceLinux/comments/6axyer/working_sp4_typecover_plug_and_play/
    ACTION=="add", SUBSYSTEM=="usb", ATTR{product}=="Surface Type Cover", RUN+="${pkgs.kmod}/bin/modprobe -r i2c_hid && ${pkgs.kmod}/modprobe i2c_hid"

    # IPTS Touchscreen (SP4)
    SUBSYSTEMS=="input", ATTRS{name}=="ipts 1B96:006A SingleTouch", ENV{ID_INPUT_TOUCHSCREEN}="1", SYMLINK+="input/touchscreen"

    # IPTS Pen (SP4)
    SUBSYSTEMS=="input", ATTRS{name}=="ipts 1B96:006A Pen", SYMLINK+="input/pen"
  '';
}
