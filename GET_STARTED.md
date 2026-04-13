# rust-nix-template

A production-ready Rust workspace template that combines Cargo's fast iteration loop with Nix's hermetic, reproducible builds. Clone it, run `direnv allow`, and you have a fully wired dev environment — no manual tool installation, no version drift between machines, no "works on my machine."

---

## Why this exists

Rust and Nix are a natural pair. Rust gives you deterministic binaries. Nix gives you deterministic build environments. Together they close the gap between "it compiles on my laptop" and "it deploys reliably everywhere."

But wiring them together well is non-trivial. The ecosystem has many tools (rust-overlay, crane, naersk, dream2nix, crate2nix...) and the wrong choices cost you in CI cache misses, broken `rust-analyzer`, or a dev loop that forces every change through a full Nix build.

This template makes the right choices for you, based on what the community has converged on in 2025–2026:

- **rust-overlay** for toolchain management (pure eval, no IFD)
- **crane** for hermetic Nix builds (two-derivation model = dependency cache + source build)
- **flake-parts** to keep the flake modular and readable
- **nix-direnv** so your shell drops in automatically and stays cached

---

## The two-tier mental model

Understanding this is the key to working with the template effectively.

**Tier A — fast loop (use Cargo directly)**

Once you're inside the dev shell, use Cargo as you normally would:

```
cargo build
cargo check
cargo test
cargo run
```

Nix's only job here is to provide the environment: the right Rust toolchain, native libraries, and env vars. Your `target/` directory stays warm, incremental compilation works, and `rust-analyzer` has everything it needs.

**Tier B — hermetic build (use Nix)**

```
nix build
nix flake check
```

This runs inside Nix's sandbox. No network, no mutable state, no `~/.cargo`. The result is a reproducible artifact. This is what CI runs and what you ship.

**The rule:** Do not try to collapse Tier A into Tier B. Forcing every `cargo check` through `nix build` burns incremental compilation without gaining anything. The hermetic guarantee comes from Tier B; the speed comes from Tier A.

---

## What you get

| Tool | What it does |
|------|--------------|
| **flake-parts** | Splits `flake.nix` into focused modules under `nix/` |
| **rust-overlay** | Reads `rust-toolchain.toml` and provides that exact toolchain from the Nix store |
| **crane** | Builds dependencies once (`cargoArtifacts`), then your source separately — CI caches the expensive part |
| **treefmt-nix** | `nix fmt` formats Rust, Nix, and TOML in one shot |
| **git-hooks-nix** | Pre-commit hooks: format, clippy, merge conflict detection, large file check |
| **mold** | Drop-in linker replacement — 3–10× faster link times for edit-rebuild cycles |
| **sccache** | Compiler cache across branches and clean builds |
| **cargo-nextest** | Faster test runner with better output and per-test isolation |
| **cargo-llvm-cov** | Source-based LLVM code coverage |
| **lldb** | Debugger, available in the shell |

---

## Requirements

- [Nix](https://nixos.org/download) with flakes enabled
- [direnv](https://direnv.net) + [nix-direnv](https://github.com/nix-community/nix-direnv) *(recommended, not required)*

---

## Getting started

```bash
git clone https://github.com/your-org/your-repo
cd your-repo

# Recommended: let direnv manage the shell
direnv allow

# Or enter manually
nix develop
```

Your shell now has the full Rust toolchain, all dev tools, and the right env vars. No `rustup`, no manual `export`, nothing else to install.

```bash
cargo build        # incremental, fast
cargo test         # uses nextest under the hood
cargo run

nix build          # hermetic, sandboxed
nix run            # run the hermetic build output
nix fmt            # format everything
nix flake check    # run all checks (clippy, fmt, tests) in Nix
```

---

## Project structure

```
.
├── flake.nix                 # Entry point — imports nix/ modules
├── rust-toolchain.toml       # Rust version pin (used by Cargo, rustup, and Nix)
├── Cargo.toml                # Workspace manifest
├── build.rs                  # Workspace build script
├── crates/
│   └── cli/                  # Default crate — rename or add more
└── nix/
    ├── toolchain.nix         # rust-overlay + crane setup
    ├── packages.nix          # Nix package definitions (crane builds)
    ├── devshell.nix          # Dev shell with tools and env vars
    ├── fmt.nix               # treefmt config (rustfmt, nixfmt, taplo)
    └── hooks.nix             # Pre-commit hooks
```

---

## Changing the Rust version

Edit `rust-toolchain.toml`. It's the single source of truth — Cargo, `rust-analyzer`, `rustup`, and Nix all read from it.

```toml
[toolchain]
channel = "stable"            # or "nightly-2026-04-01" for a pinned nightly
components = ["rust-src", "rust-analyzer", "clippy", "rustfmt"]
```

After editing, `direnv` reloads the shell automatically. The `rust-src` component is required for `rust-analyzer` to resolve standard library types — don't remove it.

---

## Adding a crate

1. Create `crates/my-crate/` with a `Cargo.toml`

2. Register it in the workspace root `Cargo.toml`:
   ```toml
   [workspace]
   members = ["crates/cli", "crates/my-crate"]
   ```

3. Expose it as a Nix package in `nix/packages.nix`:
   ```nix
   packages = {
     cli       = mkCrate "cli";
     my-crate  = mkCrate "my-crate";
     default   = mkCrate "cli";
   };
   ```

The `mkCrate` helper builds the named package using the shared `cargoArtifacts` (pre-built dependencies), so adding a new crate doesn't rebuild your entire dependency tree.

---

## Adding native dependencies (C libraries)

Add the library to both `nix/packages.nix` (hermetic build) and `nix/devshell.nix` (dev shell), keeping them in sync.

**`nix/packages.nix`** — under `commonArgs`:
```nix
buildInputs = with pkgs; [
  openssl
  sqlite   # add here
];
```

**`nix/devshell.nix`** — under `devShells.default`:
```nix
buildInputs = with pkgs; [
  openssl
  sqlite   # and here
];
```

If the library ships a `.pc` file, `pkg-config` is already in `nativeBuildInputs` and will pick it up automatically.

---

## Pre-commit hooks

Hooks are installed automatically the first time you enter the dev shell. Every commit runs:

- `treefmt` — enforces consistent formatting (Rust, Nix, TOML)
- `clippy` — lints your Rust code
- `check-merge-conflict` — catches leftover conflict markers
- `check-added-large-files` — prevents accidental binary commits

To reinstall manually:
```bash
nix develop -c pre-commit install
```

---

## Supported systems

Configured in `flake.nix`:

```nix
systems = [
  "x86_64-linux"
  "aarch64-darwin"
];
```

Add `"aarch64-linux"` or `"x86_64-darwin"` as needed. All `perSystem` modules evaluate independently per system.

---

## Binary caching (optional)

If you're on a team or want fast CI, add a binary cache. The `nixConfig` block in `flake.nix` is already wired up — just fill it in:

```nix
nixConfig = {
  extra-substituters = [ "https://your-cache.cachix.org" ];
  extra-trusted-public-keys = [ "your-cache.cachix.org-1:..." ];
};
```

With crane's two-derivation model, the dependency derivation (`cargoArtifacts`) is cached independently from your source. CI only rebuilds what changed.

---

## How the Nix build works

The crane build in `nix/packages.nix` follows this pattern:

```
craneLib.buildDepsOnly commonArgs   →  cargoArtifacts  (all deps, cached)
                                              ↓
craneLib.buildPackage { cargoArtifacts; }   →  your binary
```

`cargoArtifacts` is a derivation containing pre-compiled dependencies. It only rebuilds when `Cargo.lock` changes. Your source code changes only trigger the second derivation. This is what makes `nix flake check` fast in CI once the cache is warm.
