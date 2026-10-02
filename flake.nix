{
  description = "A small and fast code editor written in x86-64 assembly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    src = {
      url = "github:vshvedov/rhun/v0.16.2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, src }:
    # rhun is hand-written x86-64 assembly for Linux; the macOS build is
    # Apple-silicon only and needs Xcode, so only x86_64-linux is offered.
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "0.16.2";
      in
      {
        packages.rhun = pkgs.stdenvNoCC.mkDerivation {
          pname = "rhun";
          inherit version src;

          # Static, -nostdlib link: use the plain GNU assembler and linker,
          # not the cc-wrapper's ld that injects dynamic-linker/rpath flags.
          nativeBuildInputs = [ pkgs.binutils-unwrapped ];

          # The upstream suite drives a headless backend, so it runs in the sandbox.
          nativeCheckInputs = [ pkgs.python3 pkgs.git pkgs.curl ];

          postPatch = ''
            patchShebangs build.sh tools tests

            # The sandbox's /bin/sh is BusyBox ash, whose banner breaks the
            # terminal panel golden output; run that test against bash's sh.
            substituteInPlace tests/ui.sh \
              --replace-fail 'shell=/bin/sh' 'shell=${pkgs.bash}/bin/sh'
            # Only /bin/sh exists in the sandbox.
            substituteInPlace tests/commit-ai.py \
              --replace-fail '\n/bin/ln "$@"' '\n${pkgs.coreutils}/bin/ln "$@"'

            # Compose (dead key) tables: there is no /usr/share/X11 on NixOS.
            # XLOCALEDIR still overrides this at runtime.
            substituteInPlace src/app/compose.s \
              --replace-fail '"/usr/share/X11/locale"' '"${pkgs.libx11}/share/X11/locale"'
          '';

          # RHUN_DIST stays unset: the binary is not a "release build", so the
          # in-app updater only reports new versions and never tries to
          # overwrite itself in the read-only Nix store.
          buildPhase = ''
            runHook preBuild
            ./build.sh release
            # tests/run.sh rebuilds build/rhun as a debug build; keep this one.
            cp build/rhun rhun.release
            runHook postBuild
          '';

          doCheck = true;
          checkPhase = ''
            runHook preCheck
            export HOME=$TMPDIR
            git config --global user.name nix
            git config --global user.email nix@localhost
            git config --global init.defaultBranch main
            sh tests/run.sh
            runHook postCheck
          '';

          doInstallCheck = true;
          installCheckPhase = ''
            runHook preInstallCheck
            test "$($out/bin/rhun --version)" = "rhun ${version}"
            runHook postInstallCheck
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 rhun.release $out/bin/rhun
            install -Dm644 assets/rhun.desktop $out/share/applications/rhun.desktop
            install -Dm644 assets/icons/rhun.svg $out/share/icons/hicolor/scalable/apps/rhun.svg
            install -Dm644 assets/icons/rhun-256.png $out/share/icons/hicolor/256x256/apps/rhun.png
            install -Dm644 assets/icons/rhun-512.png $out/share/icons/hicolor/512x512/apps/rhun.png
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A small and fast code editor written in assembly";
            homepage = "https://github.com/vshvedov/rhun";
            license = with licenses; [ mit ofl ];
            platforms = [ "x86_64-linux" ];
            mainProgram = "rhun";
          };
        };

        packages.default = self.packages.${system}.rhun;

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.binutils-unwrapped pkgs.python3 pkgs.git ];
        };
      }
    );
}
