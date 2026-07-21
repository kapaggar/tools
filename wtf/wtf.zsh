# ── wtf: ask Claude what just went wrong ─────────────────────────────
# brew install jq                                    # if not already
# security add-generic-password -s anthropic-api-key -a "$USER" -w   # paste key; won't echo
# cat wtf.bash >> ~/.bashrc                           # or ~/.bash_profile (see note)
# source ~/.bashrc
# Usage:
#   some-command 2>&1 | wtf        # BEST: pipes real stderr, no re-run
#   wtf                            # re-runs last history cmd (with a guard)
#   wtf "extra hint for Claude"    # add context to either mode
#
# Requires: jq  (brew install jq).  Key is read from macOS Keychain (see setup).
# ─────────────────────────────────────────────────────────────────────
wtf() {
  local MODEL="${WTF_MODEL:-claude-haiku-4-5}"   # fast+cheap; override via WTF_MODEL
  local hint="$*"
  local lastcmd output rc

  # 1. Get the API key from the macOS Keychain (never hardcoded, never in a dotfile)
  local api_key
  api_key="$(security find-generic-password -s anthropic-api-key -w 2>/dev/null)"
  if [[ -z "$api_key" ]]; then
    print -u2 "wtf: no key in Keychain. Run:  security add-generic-password -s anthropic-api-key -a \"\$USER\" -w"
    return 1
  fi

  # 2. Gather the command + its output
  if [[ ! -t 0 ]]; then
    # Piped mode — read the error stream from stdin
    output="$(cat)"
    lastcmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
    lastcmd="${lastcmd% | wtf*}"          # strip the "| wtf" tail
    rc="(piped; exit code unknown)"
  else
    # Re-run mode — grab the last command from history
    lastcmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
    if [[ -z "$lastcmd" || "$lastcmd" == wtf* ]]; then
      print -u2 "wtf: no previous command found. Try piping instead:  <cmd> 2>&1 | wtf"
      return 1
    fi
    # Destructive-command guard — refuse to auto-re-run these
    if [[ "$lastcmd" =~ '(^|[[:space:]])(rm|rmdir|dd|mkfs|shutdown|reboot|kill|killall|:>|>[[:space:]]*/|sudo|chmod|chown|git[[:space:]]+push|git[[:space:]]+reset|--force|-f[[:space:]]|DROP|DELETE|TRUNCATE|curl.*-X[[:space:]]*(POST|PUT|DELETE|PATCH))' ]]; then
      print -u2 "wtf: last command looks destructive — I won't re-run it."
      print -u2 "     Re-run it yourself capturing output, then pipe:  <cmd> 2>&1 | wtf"
      return 1
    fi
    print -u2 "wtf: re-running → $lastcmd"
    output="$(eval "$lastcmd" 2>&1)"; rc=$?
  fi

  # 3. Build the request safely with jq (handles all escaping)
  local prompt body
  prompt="A shell command failed. Explain the cause in one short paragraph, then give the corrected command. Be terse, no preamble.

Command: ${lastcmd}
Exit code: ${rc}
Output:
${output}
${hint:+Extra context: ${hint}}"

  body="$(jq -n --arg m "$MODEL" --arg p "$prompt" \
    '{model:$m, max_tokens:400, messages:[{role:"user", content:$p}]}')"

  # 4. Call the API and print just the text
  local resp
  resp="$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${api_key}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$body")"

  local text
  text="$(printf '%s' "$resp" | jq -r '.content[]? | select(.type=="text") | .text' 2>/dev/null)"
  if [[ -z "$text" ]]; then
    print -u2 "wtf: no answer. Raw API response:"
    printf '%s\n' "$resp" | jq . 2>/dev/null || printf '%s\n' "$resp"
    return 1
  fi
  print -P "%F{cyan}── wtf ──%f"
  printf '%s\n' "$text"
}
