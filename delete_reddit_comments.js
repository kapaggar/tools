(async () => {
  const me = await fetch('https://www.reddit.com/api/me.json', {credentials:'include'}).then(r => r.json());
  const uh = me?.data?.modhash, user = me?.data?.name;
  if (!uh || !user) return console.error('Could not get modhash - use old.reddit.com instead');
  let n = 0;
  while (true) {
    const j = await fetch(`https://www.reddit.com/user/${user}/comments.json?limit=100`, {credentials:'include'}).then(r => r.json());
    const ids = (j.data?.children || []).map(c => c.data.name);
    if (!ids.length) break;
    for (const id of ids) {
      const res = await fetch('https://www.reddit.com/api/del', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({id, executed:'deleted', uh, renderstyle:'html'}),
        credentials: 'include'
      });
      console.log(++n, id, res.status);
      if (res.status === 429) await new Promise(r => setTimeout(r, 30000));
      await new Promise(r => setTimeout(r, 2000));
    }
  }
  console.log('Done. Deleted:', n);
})();