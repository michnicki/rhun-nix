# rhun-nix

Nix flake for [rhun](https://github.com/vshvedov/rhun), a small and fast code editor written in x86-64 assembly, with a built-in terminal, Git panel, fuzzy search and an agents panel.

## Package Summary

| Field | Value |
|---|---|
| Upstream | [github.com/vshvedov/rhun](https://github.com/vshvedov/rhun) |
| Packaged version | `0.16.2` |
| Main program | `rhun` |
| Supported systems | `x86_64-linux` |
| Flake outputs | `packages.${system}.default`, `packages.${system}.rhun`, `devShells.${system}.default` |

The package builds rhun from source with GNU `as`/`ld` into a single static binary (no libc, no shared libraries), runs the upstream test suite in the sandbox, and installs the desktop entry and icons.

## Requirements

- Nix with flakes enabled.
- An x86-64 Linux machine with an X11 or Wayland session.

## Usage

### Run without installing

```bash
nix run github:michnicki/rhun-nix
```

### Build

```bash
nix build github:michnicki/rhun-nix
./result/bin/rhun --version
```

### Install into a profile

```bash
nix profile install github:michnicki/rhun-nix
```

### Use in a NixOS or home-manager module

After adding `inputs.rhun-nix.url = "github:michnicki/rhun-nix";` to your flake, add the package to your module:

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.rhun-nix.packages.${pkgs.system}.default
  ];
}
```

For home-manager, add the same package to `home.packages`.

## Notes

- **Updates:** the package is built without `RHUN_DIST=1`, so rhun's in-app updater only tells you about new versions and never tries to replace itself in the Nix store. Update through this flake instead.
- **Compose keys:** the X11 Compose tables come from `libx11` in the Nix store, since NixOS has no `/usr/share/X11`. `XCOMPOSEFILE`, `~/.XCompose` and `XLOCALEDIR` still take precedence.
- **Runtime tools:** rhun calls `git`, your `$SHELL`, and optionally `curl`/`wget`, `claude`, `codex` or `ollama` from `PATH`. They are not bundled.

## Development

Enter the development shell to get GNU binutils, Python and Git for building and testing rhun:

```bash
nix develop github:michnicki/rhun-nix
```

## Updating

Use the update helper from the repository root:

```bash
./scripts/update-rhun.sh [--dry-run]
```

The script resolves the latest upstream release, updates `flake.nix` and `flake.lock`, verifies the build (including the upstream test suite), and commits the bump. With `--dry-run`, it skips pushing.

## License

rhun is licensed under MIT. Its built-in Iosevka font is under the SIL Open Font License.
