_: {
  perSystem = {pkgs, ...}: {
    packages.kodi-tv = pkgs.kodi-gbm.overrideAttrs (previous: {
      patches =
        previous.patches
        ++ [
          ./kodi-amdgpu-primary-plane.patch
        ];
    });
  };
}
