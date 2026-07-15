# Defer AI tool config (CLAUDE.md, skills, agents)

The original design had an `ai/` directory versioning `CLAUDE.md`, `AGENTS.md`, and Claude Code skills/agents, symlinked out to `~/.claude/`. Inspecting the actual machine showed every skill in `~/.claude/skills/` is already a symlink into `~/.agents/skills/`, itself managed by `~/.agents/.skill-lock.json` — a separate registry tool tracking installs pulled from `google/skills` and `mattpocock/skills` on GitHub. None of the currently installed skills are hand-authored. Versioning `ai/skills/` in dotfiles would mean fighting that registry tool for ownership of the same directory, for content dotfiles didn't actually originate.

Decision: drop `ai/` entirely, including `CLAUDE.md`/`AGENTS.md`, until there's actual hand-authored AI config that isn't already owned by a registry. Revisit if that changes.
