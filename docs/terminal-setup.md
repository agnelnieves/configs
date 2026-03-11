# Terminal Setup Documentation

> **Location of this file:** `~/.config/terminal-setup.md`
> **Last updated:** March 2026
> **Purpose:** Reference for agents, collaborators, and future self. Describes every tool, config file, design decision, and how to reproduce the full setup from scratch.

---

## Table of Contents

1. [Stack Overview](#1-stack-overview)
2. [Color Palette (Cursor Dark)](#2-color-palette-cursor-dark)
3. [Ghostty — Terminal Emulator](#3-ghostty--terminal-emulator)
4. [Zsh — Shell](#4-zsh--shell)
5. [Starship — Prompt](#5-starship--prompt)
6. [eza — File Listing](#6-eza--file-listing)
7. [bat — File Viewing](#7-bat--file-viewing)
8. [fzf — Fuzzy Finder](#8-fzf--fuzzy-finder)
9. [zsh-syntax-highlighting](#9-zsh-syntax-highlighting)
10. [zsh-autosuggestions](#10-zsh-autosuggestions)
11. [NVM — Node Version Manager](#11-nvm--node-version-manager)
12. [Config File Index](#12-config-file-index)
13. [Fresh Install Runbook](#13-fresh-install-runbook)
14. [Customization Guide](#14-customization-guide)
15. [Design Decisions & Rationale](#15-design-decisions--rationale)

---

## 1. Stack Overview

| Layer | Tool | Purpose |
|---|---|---|
| Terminal emulator | Ghostty | Renders the terminal window, fonts, colors, shaders |
| Shell | Zsh | The interactive shell and scripting environment |
| Prompt | Starship | The visual prompt bar (directory, git, runtimes, time) |
| File listing | eza | Modern `ls` replacement with icons and git awareness |
| File viewing | bat | Syntax-highlighted `cat` replacement |
| Fuzzy finder | fzf | Styled `Ctrl+R` history search and general fuzzy selection |
| Typing feedback | zsh-syntax-highlighting | Colors commands as you type |
| History completions | zsh-autosuggestions | Ghost text completions from history |
| Node versioning | nvm | Switches Node.js versions per project |
| Font | GeistMono NFM | Monospace font with Nerd Font icons baked in |

Everything is styled to a single color palette: **Cursor Dark** (a dark theme based on Nord-adjacent colors with a near-black `#141414` background).

---

## 2. Color Palette (Cursor Dark)

This is the palette used consistently across Ghostty, Starship, fzf, and zsh-autosuggestions. All color values come from the Ghostty `Cursor Dark` built-in theme.

| Role | Color | Hex |
|---|---|---|
| Background | Terminal bg | `#141414` |
| Black (Ansi 0) | Elevated surface | `#2A2A2A` |
| Bright Black (Ansi 8) | Subtle text / hints | `#505050` |
| Red (Ansi 1 & 9) | Errors | `#BF616E` |
| Green (Ansi 2 & 10) | Success | `#A3BE8C` |
| Yellow (Ansi 3 & 11) | Warnings / duration | `#EBCB8B` |
| Blue (Ansi 4 & 12) | Primary accent | `#81A1C1` |
| Magenta (Ansi 5 & 13) | Secondary accent | `#B48EAD` |
| Cyan (Ansi 6 & 14) | Highlights | `#88C0D0` |
| White (Ansi 7) | Body text | `#D8DEEA` |
| Bright White (Ansi 15) | Selected / active text | `#FFFFFF` |

**Design rule:** When a color is needed for UI chrome (backgrounds of prompt segments, fzf borders), use `#2A2A2A`. For subtle decorative elements (autosuggestion ghost text, clock), use `#505050`. For interactive highlights (selected items, pointers), use `#81A1C1` or `#88C0D0`. Never hardcode a color that isn't in this table — it will look out of place.

---

## 3. Ghostty — Terminal Emulator

**Config file:** `~/.config/ghostty/config`
**Docs:** https://ghostty.org/docs

Ghostty is a GPU-accelerated terminal emulator for macOS. It supports custom GLSL fragment shaders, native macOS transparency/blur, and tab-style title bars.

### Current Config

```
shell-integration-features = no-cursor   # Ghostty's own cursor management is disabled
                                          # so cursor-style below takes full effect

cursor-style = block                      # Block cursor (overrides the underline set earlier
                                          # in the file — last declaration wins in Ghostty)

theme = Cursor Dark                       # Built-in theme; defines all 16 ANSI colors

window-padding-x = 20                    # 20px horizontal breathing room from window edge
window-padding-y = 10                    # 10px vertical padding (matched to x for balance)
window-padding-balance = true            # Keeps padding consistent even when scrollbar appears

background-opacity = 0.85               # 85% opaque — background shows through slightly
background-blur = 90                    # macOS blur radius applied behind the window

macos-titlebar-style = tabs             # Integrates tabs into the title bar (final declaration
                                         # wins; transparent earlier in file is overridden)

adjust-cell-height = 35%                # Increases line height by 35% for readability
window-colorspace = "display-p3"        # Wide-gamut color rendering on supported displays

mouse-scroll-multiplier = 2             # Doubles scroll speed

font-family = "GeistMono NFM"           # Geist Mono with Nerd Font icons
font-size = 19
font-thicken = true                     # macOS font smoothing / subpixel rendering

adjust-cursor-thickness = 2
adjust-cursor-height = 10

# Quick terminal (dropdown/quake-style)
gtk-quick-terminal-layer = overlay
quick-terminal-screen = mouse           # Opens near the mouse cursor's screen
keybind = global:cmd+grave_accent=toggle_quick_terminal   # Cmd+` to toggle
quick-terminal-animation-duration = 0  # Instant open (no slide animation)
quick-terminal-size = 100%,100%        # Full screen

custom-shader = ~/.config/ghostty/shaders/matrix-hallway.glsl   # Visual shader effect
```

### Notes for Agents

- **Two `cursor-style` declarations exist** (`underline` and `block`). Ghostty uses the last one. The active cursor is `block`.
- **Two `macos-titlebar-style` declarations exist** (`transparent` and `tabs`). Active is `tabs`.
- The shader file must exist at `~/.config/ghostty/shaders/matrix-hallway.glsl`. If it's missing, Ghostty logs an error but still opens.
- The font `GeistMono NFM` must be installed system-wide. "NFM" = Nerd Font Mono variant (icons are single-width). Download from: https://www.nerdfonts.com/font-downloads

---

## 4. Zsh — Shell

**Config file:** `~/.zshrc`
**Shell:** `/bin/zsh` (macOS default since Catalina)

### Config Structure

The `.zshrc` loads tools in a specific order. Order matters, especially for the zsh plugins at the bottom.

```
1. set_win_title()         — sets the window title (currently placeholder)
2. nvm setup               — Node version manager initialization
3. starship init           — injects the prompt
4. GPG_TTY                 — needed for GPG signing in git
5. UKG-specific config     — work cert + .local/bin/env
6. eza aliases             — ls/la/ll/lla/lt
7. bat alias + BAT_THEME   — cat → bat, Nord theme
8. FZF_DEFAULT_OPTS        — fzf color/UI config
9. fzf shell source        — loads ~/.fzf.zsh (keybindings + completion)
10. zsh-autosuggestions    — must come before syntax-highlighting
11. zsh-syntax-highlighting — must be LAST
```

### Why Order Matters for Plugins

`zsh-syntax-highlighting` works by wrapping Zsh's line editor (ZLE) widgets. If anything else wraps ZLE widgets after it, highlighting can break. It must always be the final `source` line in `.zshrc`.

`zsh-autosuggestions` must come before `zsh-syntax-highlighting` for the same reason.

### eza Aliases

```zsh
alias ls='eza --icons --group-directories-first'
alias la='eza --icons -a --group-directories-first'
alias ll='eza --icons -l --git --group-directories-first'
alias lla='eza --icons -la --git --group-directories-first'
alias lt='eza --icons --tree --git-ignore'
```

- `--icons` — file type icons via Nerd Font glyphs
- `--group-directories-first` — directories always appear before files
- `--git` — adds a git status column in long view (`-l`). Shows M (modified), N (new), etc.
- `--git-ignore` — in tree view (`--tree`), hides files listed in `.gitignore` (suppresses `node_modules`, `.next`, etc.)
- `-a` — show hidden files (dotfiles)

### bat Alias

```zsh
alias cat='bat'
export BAT_THEME="Nord"
```

`bat` is aliased to `cat` so any script or habit of typing `cat file` gets syntax highlighting automatically. The Nord theme pairs well with the Cursor Dark palette — both are Nordic-inspired cool-tone dark themes.

To temporarily use real `cat` (e.g., in a script that needs plain output), use `\cat file` or `command cat file` to bypass the alias.

### fzf Config

```zsh
export FZF_DEFAULT_OPTS="
  --color=bg:#141414,bg+:#2A2A2A,fg:#D8DEEA,fg+:#FFFFFF
  --color=hl:#81A1C1,hl+:#88C0D0,info:#EBCB8B,prompt:#81A1C1
  --color=pointer:#88C0D0,marker:#A3BE8C,spinner:#B48EAD,border:#2A2A2A
  --border=rounded
  --prompt='  '
  --pointer=' '
  --marker=' '"
```

Every color maps directly to the Cursor Dark palette above. The prompt/pointer/marker icons are Nerd Font glyphs (requires GeistMono NFM).

---

## 5. Starship — Prompt

**Config file:** `~/.config/starship.toml`
**Docs:** https://starship.rs/config/
**Icon reference:** https://www.nerdfonts.com/cheat-sheet

Starship is a cross-shell prompt written in Rust. It reads the current environment (directory, git state, language runtimes) and renders a styled prompt line.

### Prompt Anatomy

The prompt is a two-line layout. Line 1 is the pill bar. Line 2 is the cursor line.

```
 ~/Downloads/project   main ✗   v20.1.0   14:03
 󰊠 ▌
```

**Line 1 — left side (pill segments):**

```
[](fg:#81A1C1)          ← left cap of blue pill (rounded left edge)
$directory              ← current path, blue background (#81A1C1), dark text (#141414)
[](fg:#81A1C1 bg:#2A2A2A) ← transition: blue → dark gray (right cap of blue, left cap of gray)
$git_branch             ← branch name with  icon, gray background (#2A2A2A)
$git_status             ← git indicators (✗ dirty, ↑ ahead, etc.), same gray pill
[](fg:#2A2A2A bg:#1E1E1E) ← transition: dark gray → darker gray
$nodejs / $rust / $golang / $php  ← runtime versions, only appear if detected
$cmd_duration           ← shows duration of last command if it took >2 seconds
[](fg:#1E1E1E)          ← right cap, closes the pill
```

**Line 1 — right side:**

```
right_format = """[](fg:#141414)$time"""
```

The  character is the left-pointing powerline cap. The time module renders behind it on the terminal background color (`#141414`), creating a subtle pill aligned to the right edge.

**Line 2:**

```
 󰊠(fg:#000000)
```

The `󰊠` is a Nerd Font glyph (a stylized cursor dot). This is the line where you actually type.

### How Powerline Pill Segments Work

The  (U+E0B6) and  (U+E0B4) characters are half-circle glyphs from the Nerd Font Powerline Extra set. They render as solid filled shapes. By setting their foreground color to match the adjacent segment's background color, they appear as smooth rounded caps.

Example: the transition from the blue directory pill to the git pill:

```
[](fg:#81A1C1 bg:#2A2A2A)
```

- The  character itself is colored `#81A1C1` (same as the directory pill's background) → looks like the right curved edge of the blue pill
- The background behind it is `#2A2A2A` (the git pill's background) → the git segment starts immediately

This technique creates seamless flowing pill shapes with no visible gaps.

### Module Breakdown

**`[directory]`**
```toml
style = "fg:#141414 bg:#81A1C1"
format = "[ $path ]($style)"
truncation_length = 3       # Show at most 3 path segments
truncation_symbol = "…/"    # Prefix when path is truncated
```
Substitutions replace full folder names with icons:
- `Documents` → `󰈙 `
- `Downloads` → ` `
- `Music` → ` `
- `Pictures` → ` `

**`[git_branch]`** and **`[git_status]`**
```toml
symbol = ""     # Nerd Font git branch icon
```
`$git_status` uses `$all_status$ahead_behind` which expands to symbols like:
- `✘` conflicted
- `?` untracked
- `!` modified
- `+` staged
- `↑` ahead of remote
- `↓` behind remote

**Runtime modules** (`nodejs`, `rust`, `golang`, `php`)
These only appear when Starship detects the relevant project file in the current directory:
- `package.json` → nodejs
- `Cargo.toml` → rust
- `go.mod` → golang
- `composer.json` → php

**`[cmd_duration]`**
```toml
min_time = 2_000   # Only shows if command took longer than 2 seconds
format = '[[ 󱦟 $duration ](fg:#EBCB8B bg:#1E1E1E)]($style)'
```
Useful for noticing when a build, test run, or slow command finishes.

**`[time]`**
```toml
disabled = false
time_format = "%H:%M"        # 24-hour clock, e.g. 14:03
format = '[[$time](fg:#505050)]($style)'
```
Renders on the right side via `right_format`. The dimmed `#505050` color keeps it visible but unobtrusive.

### Adding a New Starship Module

1. Look up the module name at https://starship.rs/config/
2. Add it to the `format` string in the correct segment (left side or right side)
3. Add its TOML configuration block at the bottom of the file
4. Use `bg:#1E1E1E` and `fg:#81A1C1` to match the existing runtime segment style, or `bg:#2A2A2A` to match the git segment style

---

## 6. eza — File Listing

**Installed via:** `brew install eza`
**Docs:** https://eza.rocks

eza is a modern replacement for `ls` written in Rust. It supports Nerd Font icons, git integration, tree views, and color theming.

### Alias Reference

| Command | Flags | Description |
|---|---|---|
| `ls` | `--icons --group-directories-first` | Basic listing with icons, dirs first |
| `la` | `--icons -a --group-directories-first` | All files including hidden |
| `ll` | `--icons -l --git --group-directories-first` | Long view with git column |
| `lla` | `--icons -la --git --group-directories-first` | Long view, all files, git |
| `lt` | `--icons --tree --git-ignore` | Tree view, respects .gitignore |

### The `--git` Column

In long view, eza adds a two-character git status column after permissions. Characters:
- `.` — unmodified
- `N` — new file
- `M` — modified
- `D` — deleted
- `R` — renamed
- `?` — untracked

The two characters represent index status (staged) and working tree status (unstaged).

---

## 7. bat — File Viewing

**Installed via:** `brew install bat`
**Docs:** https://github.com/sharkdp/bat

bat is `cat` with syntax highlighting, line numbers, a styled header, and git change indicators in the gutter.

### Configuration

```zsh
alias cat='bat'
export BAT_THEME="Nord"
```

**Theme:** Nord. Chosen because it shares color genetics with the Cursor Dark palette (cool blues, muted greens, soft yellows on a dark background). To browse alternatives:
```sh
bat --list-themes | fzf --preview="bat --theme={} --color=always ~/.zshrc"
```

**Bypassing the alias** when you need raw output (e.g. in pipes or scripts):
```sh
\cat file.txt        # backslash bypasses alias lookup
command cat file.txt # explicit built-in invocation
```

**Useful bat flags:**
- `bat -n file` — line numbers only, no decorations
- `bat -p file` — plain mode (no header, no line numbers, no git indicators)
- `bat --language=json file` — force a specific syntax language
- `bat -r 10:20 file` — show only lines 10–20

---

## 8. fzf — Fuzzy Finder

**Installed via:** `brew install fzf && $(brew --prefix)/opt/fzf/install --all --no-update-rc`
**Docs:** https://github.com/junegunn/fzf

fzf is a general-purpose interactive fuzzy finder. The shell integration provides:
- `Ctrl+R` — fuzzy search through command history (replaces built-in reverse search)
- `Ctrl+T` — fuzzy insert a file path at the cursor
- `Alt+C` — fuzzy `cd` into a subdirectory

### Color Configuration

```zsh
export FZF_DEFAULT_OPTS="
  --color=bg:#141414,bg+:#2A2A2A,fg:#D8DEEA,fg+:#FFFFFF
  --color=hl:#81A1C1,hl+:#88C0D0,info:#EBCB8B,prompt:#81A1C1
  --color=pointer:#88C0D0,marker:#A3BE8C,spinner:#B48EAD,border:#2A2A2A
  --border=rounded
  --prompt='  '
  --pointer=' '
  --marker=' '"
```

| Key | Color | Meaning |
|---|---|---|
| `bg` | `#141414` | List background |
| `bg+` | `#2A2A2A` | Selected item background |
| `fg` | `#D8DEEA` | List item text |
| `fg+` | `#FFFFFF` | Selected item text |
| `hl` | `#81A1C1` | Matched characters |
| `hl+` | `#88C0D0` | Matched characters in selected item |
| `info` | `#EBCB8B` | Match count / info line |
| `prompt` | `#81A1C1` | Prompt text color |
| `pointer` | `#88C0D0` | Current selection arrow |
| `marker` | `#A3BE8C` | Multi-select mark |
| `spinner` | `#B48EAD` | Loading indicator |
| `border` | `#2A2A2A` | Border color |

The `~/.fzf.zsh` file (generated by the installer) is sourced conditionally in `.zshrc`:
```zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
```

---

## 9. zsh-syntax-highlighting

**Installed via:** `brew install zsh-syntax-highlighting`
**Docs:** https://github.com/zsh-users/zsh-syntax-highlighting

Highlights the command line as you type, before you press Enter.

### What Gets Colored

| Token | Color |
|---|---|
| Valid command | Green (`#A3BE8C`) |
| Unknown/invalid command | Red (`#BF616E`) |
| Flags/options (`-l`, `--verbose`) | Yellow |
| Strings (`"hello"`, `'world'`) | Orange/yellow |
| File paths | Underlined |
| Redirects, pipes | White |

Colors are determined by the terminal's ANSI color palette, which Ghostty provides via the Cursor Dark theme. You don't configure the highlighting colors in `.zshrc` — they automatically inherit from the terminal theme.

### Placement in `.zshrc`

```zsh
# MUST be the last sourced plugin
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

This line must always be the very last `source` line. If anything wraps ZLE widgets after this, highlighting stops working.

---

## 10. zsh-autosuggestions

**Installed via:** `brew install zsh-autosuggestions`
**Docs:** https://github.com/zsh-users/zsh-autosuggestions

Shows a faded "ghost text" completion as you type, drawn from your command history. Press the right arrow key (`→`) or `End` to accept the full suggestion. Press `Ctrl+F` to accept one word at a time.

### Configuration

```zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#505050"
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

`fg=#505050` is the `Ansi 8` (bright black) color from the Cursor Dark palette. It renders as a very dim gray — visible against the `#141414` background but clearly distinct from your actual typed text.

### How It Picks Suggestions

By default, it uses the `history` strategy: it finds the most recent command in `~/.zsh_history` that starts with what you've typed. If you want fuzzy matching instead, you can set:
```zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
```
This falls back to `zsh completion` if no history match is found.

---

## 11. NVM — Node Version Manager

**Installed via:** `brew install nvm`
**Config:** Directory at `~/.nvm`

```zsh
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
source "$(brew --prefix nvm)/nvm.sh"
```

`mkdir -p "$NVM_DIR"` ensures the directory exists before sourcing, preventing errors on a fresh machine. NVM reads `.nvmrc` files in project directories to automatically switch Node versions.

---

## 12. Config File Index

| File | Purpose |
|---|---|
| `~/.zshrc` | Shell startup: aliases, env vars, plugin sources |
| `~/.config/starship.toml` | Prompt layout, segment colors, module config |
| `~/.config/ghostty/config` | Terminal emulator: font, colors, opacity, keybinds |
| `~/.config/ghostty/shaders/matrix-hallway.glsl` | Custom GLSL fragment shader (visual effect) |
| `~/.fzf.zsh` | Auto-generated by fzf installer; provides Ctrl+R/T/Alt+C |
| `~/.nvm/` | NVM installation directory |
| `~/.config/terminal-setup.md` | This file |

---

## 13. Fresh Install Runbook

Follow these steps in order to reproduce this setup on a new Mac.

### Prerequisites

```sh
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ghostty
# Download from https://ghostty.org — it's not in Homebrew as of 2026
```

### Step 1 — Install all CLI tools

```sh
brew install starship eza bat fzf zsh-syntax-highlighting zsh-autosuggestions nvm
```

### Step 2 — Install fzf shell integration

```sh
$(brew --prefix)/opt/fzf/install --all --no-update-rc
```
This generates `~/.fzf.zsh` (used by `.zshrc`).

### Step 3 — Install the font

Download **GeistMono NFM** (Nerd Font Mono variant) from https://www.nerdfonts.com/font-downloads
Install it via Font Book or by copying to `~/Library/Fonts/`.

### Step 4 — Copy config files

```sh
# Create config directories
mkdir -p ~/.config/ghostty/shaders

# Copy files (assuming configs are backed up or in a dotfiles repo)
cp ghostty-config ~/.config/ghostty/config
cp starship.toml ~/.config/starship.toml
cp matrix-hallway.glsl ~/.config/ghostty/shaders/matrix-hallway.glsl
cp .zshrc ~/.zshrc
```

### Step 5 — Set Zsh as default shell (if not already)

```sh
chsh -s /bin/zsh
```

### Step 6 — Verify

Restart Ghostty, then open a new terminal and check:

| Test | Expected result |
|---|---|
| Type a valid command | Turns green as you type |
| Type an invalid command | Turns red |
| Start typing a previous command | Gray ghost text appears |
| `cat ~/.zshrc` | Syntax-highlighted output with line numbers |
| `ll` in a git repo | Shows git status column |
| `lt` in a project | Tree view, no `node_modules` |
| `Ctrl+R` | Styled fuzzy history search opens |
| Look at prompt right side | Clock visible (HH:MM) |
| Run a slow command (e.g. `sleep 3`) | Duration shown in yellow after it finishes |

---

## 14. Customization Guide

### Changing the bat theme

```sh
# Preview themes interactively
bat --list-themes | fzf --preview="bat --theme={} --color=always ~/.zshrc"

# Set permanently in ~/.zshrc
export BAT_THEME="Dracula"   # or TwoDark, Monokai Extended, etc.
```

### Changing the autosuggestion color

In `~/.zshrc`, change:
```zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#505050"
```
Use any hex color. Darker = more subtle. Should be clearly dimmer than your normal text.

### Adding a new Starship segment

1. Find the module at https://starship.rs/config/
2. Add `$module_name\` to the `format` string at the correct position
3. Add the module config block at the bottom of `starship.toml`
4. Match the style of the segment it sits in:
   - Git segment: `bg:#2A2A2A`, `fg:#81A1C1`
   - Runtime segment: `bg:#1E1E1E`, `fg:#81A1C1`

### Adding a new eza alias

```zsh
alias lx='eza --icons -l --git --sort=extension --group-directories-first'
```
Common useful flags: `--sort=size`, `--sort=modified`, `--sort=extension`, `--reverse`.

### Changing the fzf keybindings

The fzf keybindings (`Ctrl+R`, `Ctrl+T`, `Alt+C`) are defined inside `~/.fzf.zsh`. To rebind or disable them, edit that file or override them in `.zshrc` after the fzf source line.

### Modifying the Ghostty shader

The shader file is at `~/.config/ghostty/shaders/matrix-hallway.glsl`. It's a GLSL fragment shader run on each rendered frame. Ghostty passes a `iTime` uniform for animation. Disable it by commenting out the `custom-shader` line in the Ghostty config.

### Adjusting the clock style

In `~/.config/starship.toml`, `[time]`:
- `time_format = "%I:%M %p"` — 12-hour with AM/PM
- `time_format = "%H:%M:%S"` — 24-hour with seconds
- `format` color: change `fg:#505050` to `fg:#D8DEEA` for a brighter clock

---

## 15. Design Decisions & Rationale

**Why Ghostty over iTerm2 or Alacritty?**
Ghostty is GPU-accelerated like Alacritty, but also supports native macOS features (transparency, blur, tabs, P3 color space) that Alacritty doesn't. It has a simpler config format than iTerm2 and is actively maintained.

**Why Starship over Oh My Zsh prompts?**
Starship is fast (written in Rust), shell-agnostic (works in zsh/bash/fish/nu), and configured with a single TOML file that's easy to version control. Oh My Zsh adds a lot of overhead and complexity.

**Why the pill/powerline segment style?**
The rounded pill aesthetic balances information density with visual clarity. Each segment has a distinct background so you can scan left-to-right: directory → git state → runtime → time. It's more readable than a flat prompt with symbols jammed together.

**Why GeistMono NFM over other Nerd Fonts?**
Geist Mono has good geometric proportions at size 19, legible at both small and large sizes, and the NFM (Mono) variant keeps all icon glyphs single-width (prevents icons from misaligning grid-based UIs like eza's tree view or prompt segments).

**Why Nord for bat vs. Cursor Dark?**
bat themes apply to file content syntax highlighting. The Cursor Dark palette was designed for terminal chrome (background, cursor, shell output), not for semantic code syntax (keywords, strings, types). Nord has a richer set of syntax rules that map well to code tokens while remaining visually harmonious with Cursor Dark's cool-tone aesthetic.

**Why `--git-ignore` on `lt` (tree) but not on `ll` (long)?**
In tree view, `node_modules` and `.next` directories make the output unreadable — often thousands of lines. In long view, those directories appear as a single line, so it's useful to see them. `--git-ignore` is therefore applied selectively where it has a practical benefit.

**Why `zsh-syntax-highlighting` must be last?**
This plugin works by replacing Zsh's ZLE (Zsh Line Editor) widget functions with wrapper functions that apply ANSI escape codes. If another plugin wraps the same widgets afterward, it bypasses the highlighting wrappers. Sourcing it last ensures no subsequent code overrides its widget hooks.
