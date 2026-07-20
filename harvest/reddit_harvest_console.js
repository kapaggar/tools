/* reddit_harvest_console.js — paste into a logged-in reddit.com tab's DevTools console.
 * Harvests engagement-heavy posts (comments+score gated) + top/controversial comments
 * across one or more subs, tags each post with source_sub, checkpoints every 20 posts,
 * and downloads a combined JSON.
 *
 * COMPLIANCE: runs in YOUR authenticated browser session against public pages you can view.
 * Single, personal, low-volume pass. No redistribution. Not the OAuth Data API.
 * Run ONE sub per paste to avoid 429 rate-limiting.
 */
(async () => {
  // ================= knobs =================
  const SUBS = ["ClaudeAI"];        // ONE sub per run is safest
  const TIME = "year";              // year | all
  const TOP_PAGES = 6;
  const SEARCH_PAGES = 1;
  const GENERAL_TERMS = ["workflow","how I use","use case","automation","agent","built","tips","saved me","system prompt","setup","productivity"];
  const WORK_TERMS = ["security","prompt injection","jailbreak","guardrails","API key","governance","compliance","data leakage","MCP","supply chain"];
  const SEARCH_TERMS = [...GENERAL_TERMS, ...WORK_TERMS];   // trim to cut runtime
  const MIN_COMMENTS = 25;          // gate A (primary)
  const MIN_SCORE = 150;            // gate B (raise 300+ for huge subs, ~30 for niche)
  const HYDRATE = 50;               // posts to comment-fetch, per sub
  const COMMENTS_PER = 18;
  const CONTROVERSIAL_PER = 6;
  const SLEEP = 5000;               // ms between requests; raise if 429s persist
  const REQUIRE_RELEVANCE = false;  // true = keep only posts matching a term/flair (use on noisy/general subs)
  const NOISE = ["megathread","daily thread","weekly thread","discussion thread","is down","outage",
    "waitlist","now available","is live","now live","pricing update","mod post","read before posting","free credits"];
  // ========================================
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const log = (...a) => console.log("%c[harvest]","color:#c60",...a);
  window.__harvest = { generated:new Date().toISOString(), timeframe:TIME,
    gate:{min_comments:MIN_COMMENTS,min_score:MIN_SCORE,require_relevance:REQUIRE_RELEVANCE}, subs:[], posts:[] };

  window.downloadHarvest = () => {
    const blob=new Blob([JSON.stringify(window.__harvest,null,2)],{type:"application/json"});
    const a=document.createElement("a"); a.href=URL.createObjectURL(blob);
    a.download=`ai_harvest_${SUBS.join("-")}_${new Date().toISOString().slice(0,10)}.json`;
    document.body.appendChild(a); a.click(); a.remove();
  };

  async function getJSON(url, tries=0) {
    try {
      const res = await fetch(url, {credentials:"include", headers:{Accept:"application/json"}});
      if (res.status === 429) { log("429 — pausing 45s"); await sleep(45000); return getJSON(url,tries); }
      if (res.status === 403 || res.status === 404) { log("skip", res.status); return null; }
      if (!res.ok) throw new Error(res.status);
      return await res.json();
    } catch(e) { if (tries < 3) { await sleep(6000); return getJSON(url, tries+1); } log("give up", e.message); return null; }
  }

  async function harvestSub(SUB) {
    const seen = {};
    const absorb = ch => { for (const c of ch||[]) { const d=c?.data; if(!d||seen[d.id]) continue;
      seen[d.id] = { id:d.id, source_sub:SUB, title:d.title, url:"https://www.reddit.com"+d.permalink,
        score:d.score, num_comments:d.num_comments, discussion_ratio:+(d.num_comments/Math.max(d.score,1)).toFixed(2),
        flair:d.link_flair_text||null, created:new Date(d.created_utc*1000).toISOString().slice(0,10),
        author:d.author, selftext:(d.selftext||"").slice(0,7000) }; } };
    async function paginate(base, pages, label) { let after="";
      for (let p=0;p<pages;p++){ const j=await getJSON(base+(after?`&after=${after}`:"")); if(!j) break;
        absorb(j.data.children); after=j.data.after; log(`r/${SUB}`,label,"pg",p+1,"pool=",Object.keys(seen).length);
        if(!after) break; await sleep(SLEEP); } }

    await paginate(`https://www.reddit.com/r/${SUB}/top.json?t=${TIME}&limit=100`, TOP_PAGES, "top");
    for (const term of SEARCH_TERMS) for (const sort of ["comments","top"])
      await paginate(`https://www.reddit.com/r/${SUB}/search.json?q=${encodeURIComponent(term)}&restrict_sr=1&sort=${sort}&t=${TIME}&limit=100`, SEARCH_PAGES, `search:${term}/${sort}`);

    const isNoise = t => NOISE.some(k => t.toLowerCase().includes(k));
    const relevant = p => SEARCH_TERMS.some(t => (p.title+" "+(p.flair||"")).toLowerCase().includes(t.toLowerCase()));
    let posts = Object.values(seen).filter(p => p.num_comments>=MIN_COMMENTS && p.score>=MIN_SCORE)
      .filter(p => !isNoise(p.title)).filter(p => !REQUIRE_RELEVANCE || relevant(p));
    posts.sort((a,b)=> b.num_comments - a.num_comments);
    const target = posts.slice(0, HYDRATE);
    log(`r/${SUB}: ${posts.length} passed gate, hydrating ${target.length}`);

    for (let i=0;i<target.length;i++){ const post=target[i];
      const j = await getJSON(`https://www.reddit.com/comments/${post.id}.json?sort=top&limit=${COMMENTS_PER}&depth=1`);
      post.comments = (j?.[1]?.data?.children||[]).filter(c=>c.kind==="t1").slice(0,COMMENTS_PER)
        .map(c=>({score:c.data.score, stance_hint:c.data.score>=0?"support":"pushback", body:(c.data.body||"").slice(0,2500)}));
      await sleep(SLEEP);
      const jc = await getJSON(`https://www.reddit.com/comments/${post.id}.json?sort=controversial&limit=${CONTROVERSIAL_PER}&depth=1`);
      post.controversial = (jc?.[1]?.data?.children||[]).filter(c=>c.kind==="t1").slice(0,CONTROVERSIAL_PER)
        .map(c=>({score:c.data.score, body:(c.data.body||"").slice(0,2000)}));
      window.__harvest.posts.push(post);
      if (window.__harvest.posts.length % 20 === 0) { downloadHarvest(); log("✓ checkpoint dumped"); }
      log(`  r/${SUB} [${i+1}/${target.length}] ${post.num_comments}c ${post.score}up  ${post.title.slice(0,50)}`);
      await sleep(SLEEP);
    }
    window.__harvest.subs.push({sub:SUB, passed:posts.length, hydrated:target.length});
    downloadHarvest(); log("✓ SUB COMPLETE — file saved");
  }

  for (const SUB of SUBS) { try { await harvestSub(SUB); } catch(e){ log("SUB FAILED", SUB, e.message); } }
  log("DONE", JSON.stringify(window.__harvest.subs), "— if no download, run: downloadHarvest()");
})();
