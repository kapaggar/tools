#!/usr/bin/env python3
"""
clean_harvest.py — turn raw Reddit harvest JSON(s) into a clean, chunked, project-ready corpus.
Usage:  python3 clean_harvest.py file1.json file2.json ...   (or a glob)
Outputs into ./corpus_out/:
  corpus_<sub>.md   one cleaned record per post (the Project knowledge files)
  INDEX.md          a map of every post (sub, date, score, comments, title, url)
  corpus.jsonl      machine-readable source of truth (re-runnable)
  STATS.md          theme distribution per sub
Handles both harvest shapes (single-sub v4 with source_sub, and older {posts:[...]}).
"""
import json, sys, glob, re, collections, os

BOT_PATTERNS = [
    r"your post is getting popular", r"we just featured it on our discord",
    r"if your post is a screenshot", r"^hey /u/", r"please reply to this message",
    r"you've also been given a special flair", r"^\s*\[deleted\]\s*$",
    r"^\s*\[removed\]\s*$", r"discord\.gg/", r"^\s*$",
]
BOT_RE = re.compile("|".join(BOT_PATTERNS), re.I)

def is_bot(body): return not body or BOT_RE.search(body.strip())

def clean_comments(comments):
    out = []
    for c in comments or []:
        b = (c.get("body") or "").strip()
        if is_bot(b): continue
        out.append({"score": c.get("score", 0),
                    "stance": c.get("stance_hint", "support" if c.get("score",0)>=0 else "pushback"),
                    "body": b[:1200]})
    return out

def load_posts(files):
    seen = {}
    for f in files:
        d = json.load(open(f))
        default_sub = (d.get("subs") or [{}])[0].get("sub") if d.get("subs") else None
        for p in d.get("posts", []):
            pid = p.get("id")
            if not pid or pid in seen: continue
            sub = p.get("source_sub") or default_sub or "unknown"
            seen[pid] = {
                "id": pid, "sub": sub, "title": p.get("title","").strip(),
                "url": p.get("url",""), "date": p.get("created",""),
                "score": p.get("score",0), "num_comments": p.get("num_comments",0),
                "discussion_ratio": p.get("discussion_ratio"),
                "flair": p.get("flair"), "selftext": (p.get("selftext") or "").strip()[:4000],
                "top_comments": clean_comments(p.get("comments")),
                "controversial": clean_comments(p.get("controversial")),
            }
    return list(seen.values())

def write_corpus(posts, outdir="corpus_out"):
    os.makedirs(outdir, exist_ok=True)
    # jsonl
    with open(f"{outdir}/corpus.jsonl","w") as f:
        for p in posts: f.write(json.dumps(p, ensure_ascii=False)+"\n")
    # per-sub markdown chunks
    by_sub = collections.defaultdict(list)
    for p in posts: by_sub[p["sub"]].append(p)
    for sub, ps in by_sub.items():
        ps.sort(key=lambda x: x["num_comments"], reverse=True)
        with open(f"{outdir}/corpus_{sub}.md","w") as f:
            f.write(f"# Corpus — r/{sub} ({len(ps)} posts)\n\n")
            for p in ps:
                f.write(f"## {p['title']}\n")
                f.write(f"- sub: r/{p['sub']} | date: {p['date']} | score: {p['score']} | "
                        f"comments: {p['num_comments']} | discussion_ratio: {p['discussion_ratio']} | flair: {p['flair']}\n")
                f.write(f"- url: {p['url']}\n\n")
                if p["selftext"]:
                    f.write(f"**OP:** {p['selftext']}\n\n")
                if p["top_comments"]:
                    f.write("**Top comments (score, stance):**\n")
                    for c in p["top_comments"][:12]:
                        f.write(f"- ({c['score']}, {c['stance']}) {c['body']}\n")
                    f.write("\n")
                if p["controversial"]:
                    f.write("**Contested / critical:**\n")
                    for c in p["controversial"][:6]:
                        f.write(f"- ({c['score']}) {c['body']}\n")
                    f.write("\n")
                f.write("---\n\n")
    # index
    posts_sorted = sorted(posts, key=lambda x:(x["sub"], -x["num_comments"]))
    with open(f"{outdir}/INDEX.md","w") as f:
        f.write(f"# Corpus index — {len(posts)} posts across {len(by_sub)} subs\n\n")
        f.write("| sub | date | score | comments | ratio | title |\n|---|---|---|---|---|---|\n")
        for p in posts_sorted:
            t = p["title"].replace("|","\\|")[:80]
            f.write(f"| r/{p['sub']} | {p['date']} | {p['score']} | {p['num_comments']} | {p['discussion_ratio']} | {t} |\n")
    # stats
    buckets={
     'coding_agents_dev':['claude code','coding','codex','repo','python','swift','vibe cod','pull request','deploy','developer','engineer'],
     'cost_limits_billing':['$','cost','token','budget','limit','usage','burn','expensive','credit','pricing','plan'],
     'image_design':['image','render','sketch','kitchen','interior','photo','draw','design','logo'],
     'life_companion':['companion','copilot my','break up','therapy','emotional','lonely','my life','relationship','decision'],
     'health_medical':['weight','fitness','diet','surgery','medical','doctor','health','symptom','lbs'],
     'guardrails_censorship':['guardrail','censor','cautious','banned','restrict','block','jailbreak','refuse','verification'],
     'memory_persistence':['memory','forget','second brain','remember','persistent','stateless'],
     'model_drama_releases':['release','launch','opus','sonnet','gpt-5','downgrade','lobotom','nerf'],
     'security_privacy':['security','privacy','exfiltrat','stole','secret','spyware','honey trap','sabotage','prompt injection','breach'],
    }
    with open(f"{outdir}/STATS.md","w") as f:
        f.write("# Theme distribution (share of posts touching each theme)\n\n")
        f.write("Caveat: harvest search terms were coding/security-seeded, so absolute shares "
                "overstate those themes. Relative cross-sub shape is directional only.\n\n")
        for sub, ps in by_sub.items():
            n=len(ps); c=collections.Counter()
            for p in ps:
                t=(p['title']+' '+p['selftext']).lower()
                for b,kws in buckets.items():
                    if any(k in t for k in kws): c[b]+=1
            f.write(f"## r/{sub} (n={n})\n")
            for b in buckets: f.write(f"- {b}: {c[b]} ({100*c[b]//n if n else 0}%)\n")
            f.write("\n")
    return by_sub

if __name__ == "__main__":
    args = sys.argv[1:]
    files = []
    for a in args: files += glob.glob(a)
    if not files: sys.exit("No input files. Usage: python3 clean_harvest.py '*.json'")
    posts = load_posts(files)
    by_sub = write_corpus(posts)
    print(f"Cleaned {len(posts)} unique posts across {len(by_sub)} subs -> ./corpus_out/")
    for s,ps in by_sub.items(): print(f"  r/{s}: {len(ps)} posts")
