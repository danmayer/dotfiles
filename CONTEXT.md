# dotfiles

Personal machine configuration (shell, git, editor) versioned in one public
repo and applied to every machine by `install.sh`. This context exists to
keep the vocabulary around "what kind of file is this and who's allowed to
write to it" precise, since that distinction drove most of the design.

## Language

**Tracked file**:
A config file whose real, canonical content lives in this git repo (e.g.
`zsh/zshrc`, `git/gitconfig`, `emacs/init.el`). Edited in the repo, never
edited directly at its `$HOME` destination.
_Avoid_: dotfile (ambiguous — could mean either the repo file or the
`$HOME` file it ends up at)

**Stub file**:
An untracked file at its real `$HOME` location that exists only to pull a
tracked file's content in — `~/.zshrc` sourcing `zsh/zshrc`, `~/.gitconfig`
including `git/gitconfig`. Deliberately *not* a symlink: the destination
path is one that some other tool (an installer, `git config --global`,
a credential helper) may also write to directly, and a stub keeps those
writes out of the tracked, public repo. `install.sh` manages only the
specific lines it's responsible for within a stub (a marker-delimited
header for `~/.zshrc`, two specific config lines for `~/.gitconfig`) and
leaves the rest of the file alone.
_Avoid_: symlink target (a stub is defined by *not* being a symlink)

**Local file**:
An untracked, machine-specific file consulted only if present, holding
content that never belongs in the tracked repo at all (e.g.
`~/.zshrc.local`). Unlike a stub, a local file has no tracked counterpart
it exists to include — it's pure per-machine addition.
_Avoid_: override (misleading — machine differences here are additive,
nothing in a local file overrides a tracked value)

Note: for zsh, the stub (`~/.zshrc`) and the local file (`~/.zshrc.local`)
are two separate files. For git, they collapse into one: `~/.gitconfig` is
simultaneously the stub (it includes tracked `git/gitconfig`) and the local
file (a per-machine identity override, e.g. a work email, just gets added
to the same file) — there is no separate `~/.gitconfig.local`.

**Real environment**:
A platform actively used for day-to-day work today — currently macOS, WSL,
and GitHub Codespaces. Only real environments are built, maintained, and
treated as first-class; they're where the design gets validated (by
building here, or by pulling the repo on the actual machine).
_Avoid_: supported platform (too broad — a platform can be nominally
covered without being a real environment; see "falls out for free")

**Falls out for free**:
A platform that isn't itself a real environment but is covered by the same
code path as one that is, at no extra authoring or maintenance cost —
plain Linux riding WSL's `platform.zsh` branch. Not separately tested,
since nobody is actually sitting at one right now.

**Out of scope**:
Explicitly not built and not carried as a placeholder stub, until the
platform becomes a real environment — currently native Windows
(PowerShell, no WSL). Distinguished from "falls out for free" by requiring
deliberate future work to add, rather than already working today.

**Registry-managed**:
Content whose install/update lifecycle is owned by a separate tool with
its own manifest — e.g. Claude Code skills tracked in
`~/.agents/.skill-lock.json`, sourced from GitHub repos like
`google/skills`. This repo never takes ownership of registry-managed
content, even content of a kind (AI tool config) that would otherwise fit
its scope — versioning it here would just fight the registry tool for the
same files.
_Avoid_: managed skill (ambiguous — could be misread as "a skill Claude
Code happens to use," not "a skill whose lifecycle a registry owns")
