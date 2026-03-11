#!/bin/bash
SPEND_CAP=50
JSON=$(cat)

# Model
model_id=$(echo "$JSON" | jq -r '.model.id')
if [[ "$model_id" == *"sonnet"* ]]; then model="sonnet"
elif [[ "$model_id" == *"opus"* ]]; then model="opus"
elif [[ "$model_id" == *"haiku"* ]]; then model="haiku"
else model=$(echo "$JSON" | jq -r '.model.display_name'); fi

# Context window
PCT=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0 | floor')
CTX=$(echo "$JSON" | jq -r '.context_window.context_window_size')
if [ "$CTX" -ge 1000000 ]; then ctx_display="$((CTX / 1000000))M"
elif [ "$CTX" -ge 1000 ]; then ctx_display="$((CTX / 1000))k"
else ctx_display="${CTX}"; fi

# Session cost from session JSON
SPEND=$(echo "$JSON" | jq -r '.cost.total_cost_usd // 0')
SPEND=${SPEND:-0}
SPEND_PCT=$(echo "$SPEND $SPEND_CAP" | awk '{printf "%.0f", $1/$2*100}')
[ "$SPEND_PCT" -gt 100 ] && SPEND_PCT=100
[ "$PCT" -gt 100 ] && PCT=100

# 10-block progress bar with color thresholds
build_bar() {
  local pct=$1 yellow=$2 red=$3
  pct=$(( pct < 0 ? 0 : pct > 100 ? 100 : pct ))
  local blocks=$((pct / 10))
  local color
  if [ "$pct" -ge "$red" ]; then color="\033[31m"
  elif [ "$pct" -ge "$yellow" ]; then color="\033[38;5;226m"
  else color="\033[32m"
  fi
  printf "${color}%s\033[0m" "$(printf '█%.0s' $(seq 1 $blocks))$(printf '░%.0s' $(seq 1 $((10-blocks))))"
}

ctx_bar=$(build_bar "$PCT" 50 70)
spend_bar=$(build_bar "$SPEND_PCT" 60 80)
spend_fmt=$(printf "\$%.2f/\$%d" "$SPEND" "$SPEND_CAP")

TOKENS_USED_RAW=$(echo "$PCT $CTX" | awk '{printf "%.0f", $1/100 * $2}')
tokens_display=$(echo "$TOKENS_USED_RAW" | awk '{
  if ($1 >= 1000000) printf "%.1fM", $1/1000000
  else if ($1 >= 1000) printf "%.1fk", $1/1000
  else printf "%d", $1
}')

printf "🤖 %s | 💬 %s / %s | 🧠 %s %d%% | 💰 %s %s\n" "$model" "$tokens_display" "$ctx_display" "$ctx_bar" "$PCT" "$spend_bar" "$spend_fmt"
