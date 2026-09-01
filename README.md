# rust-nix-template

Rust workspace. Nix provides the toolchain. Cargo runs the dev loop. Nix builds reproducibly.

## Setup

Needs [Nix](https://nixos.org/download) with flakes.

```bash
git clone https://github.com/your-org/your-repo
cd your-repo
direnv allow   # or: nix develop
```

## Commands

```bash
cargo build          # dev loop, incremental
cargo nextest run    # tests
nix build            # hermetic, sandboxed
nix flake check      # formatting (see "What changed" below)
nix fmt              # rust, nix, toml
```

Run Cargo inside the shell. Nix only provides the environment. Do not route `cargo check` through `nix build`. That discards incremental compilation.

## Layout

```
flake.nix              # imports nix/ modules
rust-toolchain.toml    # Rust version pin, single source of truth
crates/cli/            # default crate
nix/
  toolchain.nix        # rust-overlay + cargo-dyndrv overlay
  packages.nix         # cargo-dyndrv builds
  devshell.nix         # dev shell
  fmt.nix              # treefmt
```

## Common changes

**Rust version** — edit `rust-toolchain.toml`. Keep `rust-src`. rust-analyzer needs it.

**New crate** — create `crates/my-crate/`, add it to `members` in the root `Cargo.toml`, then add `my-crate = mkCrate "my-crate";` to `nix/packages.nix`.

**Native library** — add it to `buildInputs` in `nix/packages.nix` (plus `pkg-config` in `nativeBuildInputs` if the crate's build script needs it). The devshell inherits both lists.

**Binary cache** — set `nixConfig.extra-substituters` and `extra-trusted-public-keys` in `flake.nix`.

## Build model

`cargo-dyndrv` replaces crane. Cargo is used only to plan: it emits the unit
graph, and cargo-dyndrv turns each Cargo compilation unit into its own Nix
derivation, invoking `rustc` directly. Those derivations are submitted to the
daemon at build time over Nix builder-rpc and resolved with
`builtins.outputOf`, so there is no import-from-derivation.

The payoff is granularity: editing one crate rebuilds that crate and its
dependents, not the workspace. Crane rebuilt `cargoArtifacts` whenever
`Cargo.lock` changed, then the whole package on any source change.

## Nix requirements

This flake does not build on any released Nix. `builder-rpc-v0` merged in
[NixOS/nix#15793](https://github.com/NixOS/nix/pull/15793) on 2026-07-21 and is
not in 2.35.2 or earlier.

You need `pkgs.nixVersions.git` (2.36pre or newer), and this in the **daemon**
config -- `--extra-experimental-features` on the command line is not enough,
because the daemon performs the check:

```
experimental-features = nix-command flakes ca-derivations dynamic-derivations
system-features       = ... ca-derivations builder-rpc-v0
```

`builder-rpc-v0` is not advertised automatically even on master, so it must be
listed in `system-features` explicitly.

To try it without touching your system daemon, build against a local chroot
store, where the new `nix` builds in-process and needs no root:

```bash
nix build --store "local?root=$HOME/.cache/dyndrv-store" \
  --extra-experimental-features 'nix-command flakes ca-derivations dynamic-derivations' \
  --system-features 'ca-derivations builder-rpc-v0' \
  .#cli
```

## What changed from crane

Three things regressed in the swap, all upstream gaps in cargo-dyndrv:

- **The wild linker no longer applies to `nix build`.** Cargo's `--unit-graph`
  does not carry rustflags, so cargo-dyndrv never sees `CARGO_BUILD_RUSTFLAGS`.
  `readelf -p .comment result/cli` shows `GCC` rather than `Linker: Wild`.
  wild still applies in the devshell, where cargo drives the build.
- **`checks.clippy` is gone.** cargo-dyndrv has no clippy path.
- **`checks.test` is gone.** `cargo test` is not supported: the unit graph fails
  to deserialize, and test units are not passed `--test`.

Run `cargo clippy` and `cargo nextest run` in the devshell instead.
