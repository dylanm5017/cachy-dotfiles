# Dyl's Dotfiles

This repo uses a bare Git directory at `~/.dotfiles` with `$HOME` as the work tree.
Use the `dot` alias from Zsh for daily work:

```sh
dot status --short
dot add -p
dot commit -m "update dotfiles"
dot push
```

## Layout

- `~/.dotfiles` is Git metadata only. Do not store normal project files there.
- `~/.config/dotfiles/` contains helper scripts, ignore policy, docs, and package manifests.
- `~/.config/zsh/` contains shell modules loaded by `~/.zshrc`.
- App state, credentials, histories, caches, browser storage, and nested repos are ignored.

## Bootstrap

On a fresh machine, the first clone has to happen before the tracked bootstrap
script exists locally:

```sh
git clone --bare git@github.com:dylanm5017/cachy-dotfiles.git "$HOME/.dotfiles"
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
bash "$HOME/.config/dotfiles/bootstrap.sh"
```

The bootstrap can also be re-run after checkout. It sets the bare repo config,
applies the tracked checkout, and backs up checkout conflicts under
`~/.local/state/dotfiles/`.

## Restore Test

Smoke-test the restore flow without touching the real home directory:

```sh
~/.config/dotfiles/restore-check.sh
```

The restore check clones this repo into a temporary HOME, runs the bootstrap
against that temporary HOME, and verifies the expected dotfiles are present.

## Packages

Refresh package manifests without installing or removing anything:

```sh
pkglist
```

The manifests live in:

- `~/.config/dotfiles/packages/native.txt`
- `~/.config/dotfiles/packages/foreign.txt`

Review package drift:

```sh
~/.config/dotfiles/audit.sh
```

Review hidden config candidates without reading file contents:

```sh
~/.config/dotfiles/audit.sh --candidates
```

## Safety Rules

- Do not track credentials, tokens, auth files, keys, certificates, cookies, keyrings, browser state, or app databases.
- Keep separate Git repos separate. For example, `~/.config/nvim` and `~/Projects/design-system` stay outside this dotfiles repo.
- Prefer explicit curated config files over tracking whole app directories.
