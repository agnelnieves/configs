# Terminal Configs

A macOS dotfiles repo for a polished, dark-themed terminal setup. Configures **Ghostty**, **Starship**, **Zsh**, **Claude Code**, and a handful of modern CLI tools — all sharing a unified **Cursor Dark** color palette.

```
 ~/projects   main ✗   v20.1.0   14:03
 󰊠 ▌
```

## What's Inside

| File | Configures | Purpose |
|------|-----------|---------|
| `configs/ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal with transparency, blur, and quick-toggle |
| `configs/starship.toml` | [Starship](https://starship.rs) | Powerline pill-style prompt with git, runtime, and duration segments |
| `configs/zshrc` | Zsh | Aliases, plugins, fzf styling, NVM setup |
| `configs/claude-statusline.sh` | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Statusline showing model, tokens, context usage, and session cost |
| `install.sh` | Everything | One-command installer with backup and symlink support |

### CLI Tools

Installed automatically via Homebrew:

- **[eza](https://github.com/eza-community/eza)** — modern `ls` with icons and git awareness
- **[bat](https://github.com/sharkdp/bat)** — syntax-highlighted `cat` (Nord theme)
- **[fzf](https://github.com/junegunn/fzf)** — fuzzy finder for history (`Ctrl+R`), files (`Ctrl+T`), and directories (`Alt+C`)
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)** — colors valid/invalid commands as you type
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** — ghost-text completions from history
- **[nvm](https://github.com/nvm-sh/nvm)** — Node.js version manager (auto-switches via `.nvmrc`)
- **[jq](https://github.com/jqlang/jq)** — JSON processor (used by the Claude statusline)

---

## Replicating This Setup

### Prerequisites

- **macOS** (the install script checks for Darwin and exits otherwise)
- **Homebrew** (installed automatically if missing)

### Quick Start

```bash
git clone <this-repo> ~/configs
cd ~/configs
./install.sh
```

This will:

1. Install all Homebrew packages (starship, eza, bat, fzf, zsh plugins, nvm, jq)
2. Set up fzf shell integration
3. Copy config files to their expected locations (`~/.zshrc`, `~/.config/starship.toml`, `~/.config/ghostty/config`)
4. Back up any existing configs with a timestamped `.backup.*` suffix
5. Create `~/.zshrc.local` for machine-specific secrets (not tracked in git)
6. Install the Claude Code statusline into `~/.claude/`

### Install Flags

| Flag | Effect |
|------|--------|
| `--dry-run` | Preview all actions without executing them |
| `--link` | Symlink configs instead of copying (edits flow back to the repo) |

```bash
# See what would happen
./install.sh --dry-run

# Symlink so changes stay in sync with the repo
./install.sh --link
```

### Manual Steps

The installer can't automate everything. After running `install.sh`:

1. **Install Ghostty** — download from [ghostty.org](https://ghostty.org)
2. **Install the font** — grab **GeistMono NFM** from [Nerd Fonts](https://www.nerdfonts.com/font-downloads) (required for icons and powerline glyphs)
3. **(Optional) Terminal shaders** — for the matrix-hallway effect:
   ```bash
   git clone https://github.com/sahaj-b/ghostty-cursor-shaders ~/.config/ghostty/shaders
   ```
   Then uncomment the `custom-shader` line in `~/.config/ghostty/config`.

### Machine-Specific Config

`~/.zshrc.local` is created automatically and sourced at the end of `.zshrc`. Use it for anything that shouldn't be committed — work certificates, private env vars, company paths, etc.

```bash
# Example ~/.zshrc.local
export NODE_EXTRA_CA_CERTS="$HOME/Documents/work.pem"
```

### Shell Aliases

After install, these aliases are available:

| Alias | Expands To |
|-------|-----------|
| `ls` | `eza --icons --group-directories-first` |
| `la` | `eza --icons -a --group-directories-first` |
| `ll` | `eza --icons -l --git --group-directories-first` |
| `lla` | `eza --icons -la --git --group-directories-first` |
| `lt` | `eza --icons --tree --git-ignore` |
| `cat` | `bat` (with Nord theme) |

---

## Color Palette

Everything is themed around **Cursor Dark**:

| Role | Hex | Used For |
|------|-----|----------|
| Background | `#141414` | Terminal bg, prompt bg |
| Surface | `#2A2A2A` | Git segment bg, fzf selection |
| Muted | `#505050` | Autosuggestions, clock |
| Red | `#BF616E` | Errors |
| Green | `#A3BE8C` | Success indicators |
| Yellow | `#EBCB8B` | Warnings, command duration |
| Blue | `#81A1C1` | Primary accent, directory pill, prompt highlight |
| Magenta | `#B48EAD` | fzf spinner |
| Cyan | `#88C0D0` | fzf pointer, highlight |
| White | `#D8DEEA` | Body text |

---

## For AI Agents

If you are an AI agent (Claude Code, Copilot, Cursor, etc.) working in this repo, read this section before making changes.

### Starship (`configs/starship.toml`)

- **Do not remove `` or `` characters.** These are Nerd Font powerline glyphs (`U+E0B6` and `U+E0B4`) that create the pill-shaped prompt segments. They may render as blank or unknown in your environment, but they are intentional and required.
- The `format` and `right_format` strings use backslash line continuations — keep that formatting intact.
- Colors reference the Cursor Dark palette documented at the top of the file. Stay within that palette when making changes.
- Runtime modules (nodejs, rust, golang, php) only appear when relevant project files are detected — this is by design, not a bug.

### Ghostty (`configs/ghostty`)

- Ghostty config uses a last-one-wins rule for duplicate keys. `cursor-style` and `macos-titlebar-style` appear twice intentionally — the final value is what takes effect.
- The `custom-shader` line is commented out on purpose. Don't uncomment it unless the user has cloned the shaders repo.

### Zsh (`configs/zshrc`)

- **Plugin load order matters.** `zsh-syntax-highlighting` must be sourced **last** or it will break. Do not reorder the bottom of this file.
- `~/.zshrc.local` is sourced before plugins. It exists for machine-specific secrets and is git-ignored — never create or modify it in commits.

### Claude Statusline (`configs/claude-statusline.sh`)

- Reads session JSON from stdin and outputs a single formatted line.
- `SPEND_CAP` at the top controls the cost bar denominator. Default is `$50`.
- Uses ANSI color codes for the progress bars (green/yellow/red thresholds). These are not Cursor Dark palette colors — they're standard terminal colors for at-a-glance readability.

### General Rules

- All configs target **macOS**. Don't add Linux-specific paths or conditionals without explicit instruction.
- The `.gitignore` excludes `*.local`, `*.backup.*`, and `.DS_Store` — respect these patterns.
- When editing config files, preserve the existing comment style and section dividers (`# ─── Section ───`).
- The `install.sh` script backs up existing files before overwriting. Don't remove or bypass that behavior.
- Refer to `docs/terminal-setup.md` for deep documentation on design decisions, the full color palette, and the fresh-install runbook.
