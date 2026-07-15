# dotfiles

Personal shell, editor, and git configuration — kept small on purpose.

## Goals

- **Slim zsh, not a framework.** Plain zsh with a handful of small files. No
  oh-my-zsh/prezto/zinit. A few built-ins turned on, sane history, a minimal
  prompt, aliases, functions. If it's not earning its keep, it doesn't go in.
- **One repo, every machine.** macOS, WSL, and GitHub Codespaces are the
  three real, actively-used environments (a Mac day-to-day, WSL on another
  machine, Codespaces for cloud work) and all get full support. Plain Linux
  falls out of the same code path as WSL for free. Native Windows
  (PowerShell, no WSL) is explicitly out of scope — see Non-goals.
- **Public, and public-safe.** This repo is public — zero extra auth
  friction cloning it on any machine or Codespace, and it forces the
  discipline of never committing a secret, which is what went wrong with
  the old private repo. Machine-specific and secret config lives in
  untracked local files that this repo sources but never stores.
- **Emacs as the editor.** Minimal `init.el` using built-in `package.el`,
  no vendored packages committed to git.

## Non-goals

- Not a Linux package manager / full machine-provisioning tool. `install.sh`
  symlinks config into place and picks a shell; it does not install a big
  list of packages. (macOS gets one optional `Brewfile` for the handful of
  CLI tools the config assumes exist.)
- Not a "one dotfiles repo to rule every tool ever installed." If a tool's
  config is large, plugin-heavy, or machine-specific, it stays out.
- **Not native Windows (PowerShell, no WSL).** WSL is the real, actively
  used Windows path and gets full support; a Windows box without WSL is not
  a real environment right now, so there's no `profile.ps1` or PowerShell
  config in this repo. Add it later as a deliberate addition if that
  changes — not as a speculative stub carried untested from day one.
- **Not AI tool config (for now).** `~/.claude/skills` on this machine is
  already owned by a separate registry tool (`~/.agents/skills` +
  `~/.agents/.skill-lock.json`, tracking installs pulled from GitHub repos
  like `google/skills` and `mattpocock/skills`) — every skill currently
  installed came from that registry, none are hand-authored. Dotfiles
  versioning `ai/skills/` would fight that tool for ownership of the same
  directory for zero benefit. `CLAUDE.md`/`AGENTS.md` are dropped from this
  repo too, for the same reason: out of scope until there's actually
  hand-authored AI config that isn't already managed elsewhere. Revisit
  this if that changes.

## Layout

```
dotfiles/
├── README.md
├── install.sh              # symlinks + manages ~/.zshrc and ~/.gitconfig, idempotent
├── Brewfile                 # optional, macOS only: brew bundle install
│
├── zsh/
│   ├── zshrc                # thin entrypoint, sources the files below
│   ├── aliases.zsh
│   ├── functions.zsh
│   ├── path.zsh
│   └── platform.zsh         # OS/Codespaces/WSL conditionals live in one place
│
├── git/
│   ├── gitconfig
│   └── gitignore_global
│
├── emacs/
│   └── init.el               # minimal, package.el only, no vendored elisp
│
└── ssh/
    └── config.example        # template only; real config is untracked
```

Every subdirectory is named for the tool it configures, and every file in it
is a real config file (not a script fragment) — `git diff` on this repo
should read like an ordinary config change, not like reverse-engineering an
installer.

## How `install.sh` works

- **`#!/usr/bin/env bash`, written for bash 3.2.** Bash for readability
  (arrays, `[[ ]]`) over strict POSIX `sh`, but no associative arrays or
  other 4.0+ features — macOS ships bash 3.2 at `/bin/bash` and always
  will (Apple won't ship anything GPLv3), so targeting 3.2 means the script
  runs everywhere without requiring `brew install bash` first as a
  bootstrap dependency.
- **Explicit, not clever.** It's a short, readable list of
  `source -> target` symlink pairs (e.g. `emacs/init.el ->
  ~/.emacs.d/init.el`), plus two "untracked file that pulls in the tracked
  one" steps for `~/.zshrc` and `~/.gitconfig` (see below). No "symlink
  every dotfile in this directory" magic — GitHub's own Codespaces docs
  recommend reading a dotfiles `install.sh` before trusting it, and an
  explicit list is what makes that five-second read possible.
- **Idempotent.** Safe to re-run any time (including "update this machine
  after `git pull`"). Existing real files are backed up once
  (`~/.emacs.d/init.el` → `~/.emacs.d/init.el.pre-dotfiles`) rather than
  clobbered silently.
- **Stub, not symlink, for files tools write to: `~/.zshrc` and
  `~/.gitconfig`.** Both are files that other tools (nvm/Homebrew/LM
  Studio installers for `~/.zshrc`; `gh auth setup-git`, credential
  helpers, and `git config --global` generally for `~/.gitconfig`)
  routinely write to directly by convention. If either were a symlink into
  the repo, those writes would land in the *tracked, public* file. So
  neither is a symlink:
  - `~/.zshrc` is an untracked stub with a marker line; `install.sh`
    manages only the header above the marker and never touches anything
    appended below it (see **zsh setup**).
  - `~/.gitconfig` is an untracked file whose only `install.sh`-managed
    line is a native git `[include] path = <repo>/git/gitconfig` — no
    marker needed here, since `git config --global` writes are structured
    (they edit or add `[section]` blocks, they don't blindly append text),
    so anything a tool writes coexists safely with the include line in the
    same untracked file (see **git setup**).
- **OS-aware.** Detects macOS / WSL / Codespaces (`$CODESPACES`,
  `$WSL_DISTRO_NAME`, `uname`) and skips steps that don't apply — e.g. no
  Homebrew step on Codespaces or WSL.
- **Discovered automatically by Codespaces.** GitHub Codespaces looks for
  `install.sh` (among a few conventional names) in whatever repo you pick
  under *Settings → Codespaces → Dotfiles* and runs it when a codespace is
  created — see [Personalizing GitHub Codespaces for your
  account](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account).
  Codespaces can clone a private repo you own just as well as a public one
  (it authenticates as you), so being public here is a deliberate choice
  for convenience and secret-discipline, not a technical requirement.

### Codespaces compatibility checklist

Codespaces runs `install.sh` non-interactively right after cloning it, on a
throwaway container — that puts a few hard constraints on how the script is
written, beyond what a "just for my own Mac" script would need:

- **Non-interactive.** No `read` prompts, no `sudo` password prompts that
  block waiting for input. Anything that needs a choice gets a sane default
  instead of a question.
- **Location-agnostic.** Never hardcode `~/projects/dotfiles`. Codespaces
  clones the dotfiles repo to its own path (`~/dotfiles` at the time of
  writing, but not guaranteed), so `install.sh` resolves its own directory
  (`cd "$(dirname "$0")"`) and builds symlink targets off that, not off a
  path assumed from my machines.
- **No sudo assumed.** Symlinking into `$HOME` and editing `~/.zshrc` never
  need root. The one step that historically wants root — `chsh -s
  $(which zsh)` — is wrapped in a check that no-ops (not errors) if `chsh`
  isn't available or the shell is already zsh; Codespaces containers are
  zsh-or-bash depending on image, and changing login shell isn't guaranteed
  to affect the integrated terminal anyway, so this step is a best-effort
  convenience, not a dependency of anything else in the script.
- **Fast and offline-tolerant where possible.** The base symlink + zsh setup
  needs no network. The only optional network step is `brew bundle` from
  `Brewfile`, which is skipped entirely on Codespaces (`$CODESPACES` check)
  so a flaky network during container creation can't break the base setup.
- **Idempotent re-run.** Same script runs on first create and on every
  manual `git pull && ./install.sh` afterward — no "first-run only" branch
  that would behave differently in Codespaces vs. an existing machine.
- **Exits 0 on success, non-zero + clear message on real failure.**
  Codespaces surfaces script failures in the creation log; a silent partial
  failure is worse than a loud one.

## zsh setup

`~/.zshrc` is **not** a symlink — it's an untracked stub that `install.sh`
writes and can safely rewrite on every run:

```sh
# --- managed by dotfiles install.sh: do not edit above this line ---
source "/path/to/dotfiles/zsh/zshrc"
# --- dotfiles: anything below this line is untouched by install.sh ---
```

`install.sh` locates the marker line (if `~/.zshrc` already exists) and
rewrites only the header above it, leaving everything below — including
whatever tool installers have appended — exactly as-is. On a machine with
no `~/.zshrc` yet, it writes the header followed by just the marker line.

The real content lives in `zsh/zshrc` (tracked, sourced by the stub), which
just sources, in order:

1. `path.zsh` — `PATH` setup
2. `platform.zsh` — the one place OS/environment-specific branches live
3. `aliases.zsh`
4. `functions.zsh`
5. `~/.zshrc.local` **if it exists** — untracked, per-machine, never
   committed (see Secrets below)

No plugin manager, no async prompt framework. Built-in zsh completion,
`vcs_info` for a git-branch-aware prompt, and `bindkey`/`setopt` tuning is
enough for a fast, boring shell. If a future need genuinely requires a
plugin manager, that's a deliberate decision to revisit this doc, not a
default.

## git setup

`~/.gitconfig` is **not** a symlink — it's an untracked file that
`install.sh` ensures starts with:

```ini
[include]
    path = /path/to/dotfiles/git/gitconfig
[core]
    excludesfile = /path/to/dotfiles/git/gitignore_global
```

Both paths are resolved to absolute paths by `install.sh` at run time (same
location-agnostic resolution used everywhere else — never a hardcoded
`~/projects/dotfiles`). `core.excludesfile` has to be set here rather than
inside the tracked `git/gitconfig` itself: git's `include.path` resolves
relative paths relative to the including file, but `core.excludesfile`
doesn't get that treatment, so a relative value baked into the tracked file
would resolve against the wrong directory on a machine where the repo is
cloned somewhere else. Setting both lines directly in the untracked,
already-machine-specific `~/.gitconfig` sidesteps the problem entirely.

`install.sh` only checks that these two lines are present (adding them
once if missing) and otherwise leaves `~/.gitconfig` alone — identity,
aliases, and every other setting live in the tracked `git/gitconfig` and
flow in through the include. Anything `git config --global ...` writes
(by me, by `gh auth setup-git`, by a credential helper) lands in
`~/.gitconfig` itself, below these lines, exactly like it would without
dotfiles involved at all — because `~/.gitconfig` already *is* the
per-machine file, there's no separate `.gitconfig.local` to maintain.

## Emacs

`emacs/init.el` is intentionally small: package.el + `package-selected-packages`,
a short list of built-in improvements, and Emacs configured as `$EDITOR`.
No vendored `.el` files or `elpa/` directory are committed — packages
install on first run and live in `~/.emacs.d/elpa`, which is gitignored.

Terminal-first, not GUI-first: two of the three real environments (WSL,
Codespaces) only ever run `emacs -nw` in a terminal, so the baseline
config — `package.el` setup, sane defaults, behaving well as `$EDITOR` for
things like `git commit` — is what has to work everywhere. Anything
GUI-only (fonts, frame size/position, macOS-specific PATH fixups for the
windowed app) is guarded behind `(display-graphic-p)` so it's a no-op under
`-nw` instead of erroring or silently doing nothing useful.

## Secrets & machine-specific config

**Nothing in this repo should ever require a secret to be useful.** Per-machine
or sensitive values live in small untracked files that the tracked config
sources *if present* and silently skips otherwise:

- `~/.zshrc.local` — machine-specific env vars, tokens, work-only aliases,
  sourced by `zsh/zshrc` if present
- `~/.gitconfig` itself — e.g. a work email override for one machine; see
  **git setup** above for why this file, not a separate `.local` file, is
  already the right place for that
- `ssh/config.example` is committed; the real `~/.ssh/config` is never
  touched by this repo beyond that example

All `*.local` and `*.local.*` patterns are covered by this repo's
`.gitignore`, and `git/gitignore_global` adds the same for every other repo
on the machine. Before pushing, a quick secret-scan (`gitleaks detect` or
equivalent) is worth running once as a habit, but the real guardrail is
"secrets never get typed into a tracked file in the first place."

## Platforms

Three real, actively-used environments drive this design; everything else
either falls out of them for free or is explicitly out of scope.

| Platform | Status | Shell | Notes |
|---|---|---|---|
| macOS | Real, daily use — built and tested here | zsh (default since Catalina) | `Brewfile` covers the small CLI toolset assumed by the config |
| WSL | Real, daily use on another machine (active Claude Code sessions there today) | zsh | First-class, not an afterthought; `platform.zsh` adds WSL-specific bits (e.g. clipboard interop) behind a `$WSL_DISTRO_NAME` check. Verified by pulling this repo on that machine, not from here |
| GitHub Codespaces | Real, built and tested via an actual codespace | zsh | `install.sh` auto-run by Codespaces; detected via `$CODESPACES` to skip machine-only steps |
| Linux (non-WSL) | Falls out of the WSL code path for free | zsh | Same `platform.zsh` branch as WSL minus the WSL-specific bits; not separately tested since it's not a real environment right now, but costs nothing extra to support |
| Windows (native, no WSL) | Out of scope | — | See Non-goals |

## Using it on a new machine

Clone location isn't fixed — `install.sh` resolves its own directory at
run time, so it doesn't matter where the repo lives. In practice that's
`~/projects/dotfiles` on macOS (matches how every other repo is organized
there) and `~/dotfiles` elsewhere (WSL, and Codespaces' own default clone
path):

```sh
git clone https://github.com/danmayer/dotfiles.git ~/dotfiles   # or ~/projects/dotfiles on macOS
cd ~/dotfiles
./install.sh
```

Re-run `./install.sh` any time after `git pull` to pick up new symlinks.

## Updating across machines

This repo has no branching model beyond `main` — edit, commit, push from
whichever machine, `git pull && ./install.sh` on the others. No fork/upstream
split, no rebasing a personal branch onto someone else's changes: it's a
single owner, so the simplest possible workflow is the right one.
