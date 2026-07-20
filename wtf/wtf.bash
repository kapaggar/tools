# ── wtf: ask Claude what just went wrong (bash version) ──────────────
# Usage:
#   some-command 2>&1 | wtf        # BEST: pipes real stderr, no re-run
#   wtf                            # re-runs last history cmd (with a guard)
#   wtf "extra hint for Claude"    # add context to either mode
#
# Requires: jq  (brew install jq).  Key read from macOS Keychain (see setup).
# Add to ~/.bashrc (or ~/.bash_profile on macOS), then: source that file.
# ─────────────────────────────────────────────────────────────────────
wtf() {
  local MODEL="${WTF_MODEL:-claude-haiku-4-5}"   # fast+cheap; override via WTF_MODEL
  local hint="$*"
  local lastcmd output rc

  # 1. API key from the macOS Keychain (never hardcoded, never in a dotfile)
  local api_key
  api_key="$(security find-generic-password -s anthropic-api-key -w 2>/dev/null)"
  if [ -z "$api_key" ]; then
    printf '%s\n' "wtf: no key in Keychain. Run:  security add-generic-password -s anthropic-api-key -a \"\$USER\" -w" >&2
    return 1
  fi

  # 2. Gather the command + its output
  if [ ! -t 0 ]; then
    # Piped mode — read the error stream from stdin
    output="$(cat)"
    lastcmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
    lastcmd="${lastcmd% | wtf*}"
    rc="(piped; exit code unknown)"
  else
    # Re-run mode — grab the last command from history
    lastcmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
    case "$lastcmd" in
      ""|wtf*)
        printf '%s\n' "wtf: no previous command found. Try piping instead:  <cmd> 2>&1 | wtf" >&2
        return 1 ;;
    esac
    # Destructive-command guard — refuse to auto-re-run these (case-insensitive)
    local re='(^|[^a-zA-Z])(rm|rmdir|dd|mkfs|shutdown|reboot|kill|killall|sudo|chmod|chown|:>|>[[:space:]]*/|git[[:space:]]+push|git[[:space:]]+reset|--force|-f[[:space:]]|DROP|DELETE|TRUNCATE|curl.*-X[[:space:]]*(POST|PUT|DELETE|PATCH))'
    local had_nocase=0
    shopt -q nocasematch && had_nocase=1
    shopt -s nocasematch
    if [[ "$lastcmd" =~ $re ]]; then
      [ "$had_nocase" -eq 0 ] && shopt -u nocasematch
      printf '%s\n' "wtf: last command looks destructive — I won't re-run it." >&2
      printf '%s\n' "     Re-run it yourself capturing output, then pipe:  <cmd> 2>&1 | wtf" >&2
      return 1
    fi
    [ "$had_nocase" -eq 0 ] && shopt -u nocasematch
    printf '%s\n' "wtf: re-running → $lastcmd" >&2
    output="$(eval "$lastcmd" 2>&1)"; rc=$?
  fi

  # 3. Build the request safely with jq (handles all escaping)
  local prompt body
  prompt="A shell command failed. Explain the cause in one short paragraph, then give the corrected command. Be terse, no preamble.

Command: ${lastcmd}
Exit code: ${rc}
Output:
${output}"
  [ -n "$hint" ] && prompt="${prompt}
Extra context: ${hint}"

  body="$(jq -n --arg m "$MODEL" --arg p "$prompt" \
    '{model:$m, max_tokens:400, messages:[{role:"user", content:$p}]}')"

  # 4. Call the API and print just the text
  local resp text
  resp="$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${api_key}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$body")"

  text="$(printf '%s' "$resp" | jq -r '.content[]? | select(.type=="text") | .text' 2>/dev/null)"
  if [ -z "$text" ]; then
    printf '%s\n' "wtf: no answer. Raw API response:" >&2
    printf '%s\n' "$resp" | jq . 2>/dev/null || printf '%s\n' "$resp"
    return 1
  fi
  printf '\033[36m── wtf ──\033[0m\n'
  printf '%s\n' "$text"
}
