# Skill Registry — archlinux-setup

Generated: 2026-05-15 (updated)

## User Skills

| Skill | Trigger | Source |
|-------|---------|--------|
| go-testing | Go tests, teatest, test coverage | `~/.claude/skills/go-testing/SKILL.md` |
| judgment-day | "judgment day", "dual review", "juzgar" | `~/.claude/skills/judgment-day/SKILL.md` |
| issue-creation | Creating GitHub issues, reporting bugs | `~/.claude/skills/issue-creation/SKILL.md` |
| branch-pr | Creating PRs, preparing changes for review | `~/.claude/skills/branch-pr/SKILL.md` |
| skill-creator | Create new skills, add agent instructions | `~/.claude/skills/skill-creator/SKILL.md` |

## Project Conventions

| Source | Path | Notes |
|--------|------|-------|
| Global CLAUDE.md | ~/.claude/CLAUDE.md | User preferences, personality, rules |

## Compact Rules

### Shell Scripts (this project)
- All scripts use `set -euo pipefail`
- Color-coded output helpers: `info()`, `ok()`, `warn()`, `fail()`, `step()`
- Package installation via `pac_install` (pacman) and `aur_install` (yay) wrappers
- Configs stored in `configs/` and copied to `~/.config/` at install time
- Scripts support both CLI flags (`--all`, `--gnome`, etc.) and interactive menu
- Use `bat/rg/fd/sd/eza` instead of `cat/grep/find/sed/ls`

### GNOME Extensions (dock-magnify, calendar-tweaks, panel-tweaks)
- JavaScript/GJS with GNOME Shell imports (Clutter, GLib, Graphene, St, Gio, Main)
- Extension class extends `Extension` from `resource:///org/gnome/shell/extensions/extension.js`
- Shell-version range: 45-50
- Follows GNOME extension conventions: `metadata.json`, `extension.js`, `stylesheet.css`
- `dock-magnify`: icon magnification on hover (Clutter animations)
- `calendar-tweaks`: CSS-only width collapse of message list + x_expand toggle
- `panel-tweaks`: rearranges panel layout — quick settings left with Arch icon, Vitals+clipboard center, date right

### judgment-day
- Launch 2 independent blind judge sub-agents in parallel
- Each reviews the same target without seeing the other's findings
- Synthesize findings, apply fixes, re-judge until both pass
- Escalate after 2 failed iterations

### issue-creation
- Follow issue-first enforcement — issues before PRs
- Use GitHub issue templates (bug report or feature request)
- Include reproduction steps for bugs, acceptance criteria for features

### branch-pr
- PRs must reference an existing issue (issue-first enforcement)
- Use conventional commit style for PR titles
- Include test plan in PR description

### go-testing
- Use table-driven tests with descriptive subtest names
- For Bubbletea TUI: use teatest package for integration tests
- Test golden path + edge cases
- Use testify/assert for assertions

### skill-creator
- Follow Agent Skills spec format (frontmatter + markdown body)
- Include: name, description with trigger, when-to-use, rules
- Keep skills focused — one concern per skill
- Generate compact rules (5-15 lines) for registry injection
