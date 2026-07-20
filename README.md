# tools

Personal utilities for harvesting and analyzing public AI-community discussion, plus a shell helper.

## harvest/
**`reddit_harvest_console.js`** — paste into a logged-in `reddit.com` tab's DevTools console.
Collects engagement-gated posts (comments + score) with top and controversial comments across
one or more subreddits, tags each post with `source_sub`, checkpoints every 20 posts, and
downloads a combined JSON.

- Edit the knobs at the top (`SUBS`, `MIN_COMMENTS`, `MIN_SCORE`, `HYDRATE`, `SEARCH_TERMS`,
  `REQUIRE_RELEVANCE`). Run **one sub per paste** to avoid 429 rate-limiting.
- Keep the tab focused; leave `SLEEP` >= 5000 for gentle pacing.
- Compliance: runs in your own authenticated session against public pages. Single personal
  low-volume pass, no redistribution. Not the Reddit OAuth Data API (which requires approval).

**`clean_harvest.py`** — turns raw harvest JSON(s) into a clean, chunked corpus.
```
python3 clean_harvest.py 'ai_harvest_*.json'
```
Emits `corpus_<sub>.md` (one cleaned record per post), `INDEX.md`, `STATS.md`, and `corpus.jsonl`.
Strips bot/automod boilerplate; dedupes across files; normalizes schema for cross-sub analysis.

## wtf/
Shell helper: sends your last failed command + its output to the Anthropic API and prints a
one-paragraph diagnosis and fix. `wtf.zsh` (macOS default shell) and `wtf.bash`.

Setup:
```
brew install jq
security add-generic-password -s anthropic-api-key -a "$USER" -w   # key -> macOS Keychain
cat wtf/wtf.zsh >> ~/.zshrc && source ~/.zshrc                     # or wtf.bash into ~/.bash_profile
```
Usage: `cmd 2>&1 | wtf` (best), or bare `wtf` (re-runs last cmd, guarded against destructive ones).
Key is read from the Keychain per-call — never hardcoded. Override model with `WTF_MODEL=...`.

## Security notes
- `.gitignore` excludes all harvested data (`*.json*`, `corpus_*`) and any secrets — **do not commit
  the corpus or keys**.
- The `wtf` destructive-command guard is a safety net, not exhaustive; pipe mode never re-runs.
