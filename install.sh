#!/usr/bin/env bash
set -euo pipefail

# ─── Flags ────────────────────────────────────────────────────────────────────
DRY_RUN=false
LINK_MODE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --link)    LINK_MODE=true ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: install.sh [--dry-run] [--link]"
      exit 1
      ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "  $*"; }
info() { echo "→ $*"; }
ok()   { echo "✓ $*"; }
skip() { echo "  (skip) $*"; }
dry()  { echo "  [dry-run] $*"; }

run() {
  if $DRY_RUN; then
    dry "$*"
  else
    eval "$*"
  fi
}

# ─── 1. OS check ──────────────────────────────────────────────────────────────
info "Checking OS..."
if [[ "$(uname)" != "Darwin" ]]; then
  echo "✗ This dotfiles setup is macOS-only. Detected: $(uname)"
  exit 1
fi
ok "macOS confirmed"

# ─── 2. Homebrew ──────────────────────────────────────────────────────────────
info "Checking Homebrew..."
if command -v brew &>/dev/null; then
  skip "Homebrew already installed ($(brew --version | head -1))"
else
  log "Installing Homebrew..."
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  ok "Homebrew installed"
fi

# ─── 3. Brew packages ─────────────────────────────────────────────────────────
info "Installing brew packages (already-installed ones will be skipped)..."
PACKAGES="starship eza bat fzf zsh-syntax-highlighting zsh-autosuggestions nvm jq"
run "brew install $PACKAGES"
ok "Brew packages ready"

# ─── 4. fzf shell integration ─────────────────────────────────────────────────
info "Setting up fzf shell integration..."
run '"$(brew --prefix)/opt/fzf/install" --all --no-update-rc'
ok "fzf shell integration ready"

# ─── 5. Config files ──────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

install_config() {
  local src="$1"
  local dst="$2"

  info "Installing $dst..."

  # Ensure destination directory exists
  run "mkdir -p '$(dirname "$dst")'"

  # Back up if it exists and differs
  if [[ -f "$dst" ]] && ! diff -q "$src" "$dst" &>/dev/null; then
    local backup="${dst}.backup.${TIMESTAMP}"
    log "Backing up existing file → $backup"
    run "cp '$dst' '$backup'"
  elif [[ -f "$dst" ]]; then
    log "Destination matches source, no backup needed"
  fi

  if $LINK_MODE; then
    run "ln -sf '$src' '$dst'"
    ok "Symlinked $src → $dst"
  else
    run "cp '$src' '$dst'"
    ok "Copied → $dst"
  fi
}

install_config "$DOTFILES_DIR/configs/zshrc"       "$HOME/.zshrc"
install_config "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
install_config "$DOTFILES_DIR/configs/ghostty"      "$HOME/.config/ghostty/config"

# ─── 6. .zshrc.local template ─────────────────────────────────────────────────
info "Checking ~/.zshrc.local..."
if [[ -f "$HOME/.zshrc.local" ]]; then
  skip "~/.zshrc.local already exists — leaving it alone"
else
  log "Creating ~/.zshrc.local from template..."
  if $DRY_RUN; then
    dry "Would create ~/.zshrc.local with machine-specific config template"
  else
    cat > "$HOME/.zshrc.local" <<'EOF'
# ~/.zshrc.local — machine-specific config (not tracked in dotfiles)
# Add anything here that should not be shared publicly:
#   - Work certificates
#   - Private env vars
#   - Company-specific paths
#
# Example:
# export NODE_EXTRA_CA_CERTS="$HOME/Documents/work.pem"
# NODE_USE_SYSTEM_CA=1
# . "$HOME/.local/bin/env"
EOF
  fi
  ok "Created ~/.zshrc.local"
fi

# ─── 7. Claude Code statusline ────────────────────────────────────────────────
info "Installing Claude Code statusline..."
run "mkdir -p '$HOME/.claude'"
install_config "$DOTFILES_DIR/configs/claude-statusline.sh" "$HOME/.claude/statusline.sh"
run "chmod +x '$HOME/.claude/statusline.sh'"

SETTINGS="$HOME/.claude/settings.json"
STATUS_LINE_JSON='{"statusLine":{"type":"command","command":"~/.claude/statusline.sh"}}'
info "Merging statusLine into $SETTINGS..."
if $DRY_RUN; then
  dry "Would merge statusLine key into $SETTINGS"
elif [[ -f "$SETTINGS" ]]; then
  TMP="$(mktemp)"
  jq --argjson sl "$STATUS_LINE_JSON" '. + $sl' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  ok "Merged statusLine into existing $SETTINGS"
else
  echo "$STATUS_LINE_JSON" | jq '.' > "$SETTINGS"
  ok "Created $SETTINGS with statusLine config"
fi

# ─── 8. Manual steps ──────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
echo "  Manual steps required:"
echo ""
echo "  1. Install Ghostty: https://ghostty.org"
echo "  2. Install font GeistMono NFM: https://www.nerdfonts.com/font-downloads"
echo "  3. (Optional) Shaders:"
echo "     git clone https://github.com/sahaj-b/ghostty-cursor-shaders ~/.config/ghostty/shaders"
echo "     Then uncomment the custom-shader line in ~/.config/ghostty/config"
echo "────────────────────────────────────────────────────────"
echo ""

# ─── 9. Final message ─────────────────────────────────────────────────────────
ok "Done! Run: source ~/.zshrc  (or restart your terminal)"
