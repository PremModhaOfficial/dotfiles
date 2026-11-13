# Code lookup: command forms (detail)

Only the forms; the rules are inline. `graft` is not installed on every machine —
check it is on PATH before using any line below.

- `graft skeleton <file>` — a file's API in ~200 tokens.
- `graft ask "<question>" --source` — locate and understand.
- `graft grep "<literal>"` — every occurrence.
- `graft callers <sym> --depth 2` — blast radius before a signature change.
- `graft map` — orient in an unfamiliar repo.
- deepwiki `ask_wiki_question` — `repoName: "nats-io/nats.rs"` plus the question;
  answers API questions grounded in the repo wiki. One call returned every stream,
  consumer and KV signature that minutes of grepping had missed.

On deepwiki, `ask_wiki_question` is the only callable tool. `read_wiki_structure` and
`read_wiki_contents` exist but are marked `hidden` for this server, so calling them by
name fails — check the exposure before planning a call:

```bash
python3 -c "import json;print(json.load(open('$HOME/.pi/agent/mcp.json'))['mcpServers']['deepwiki']['toolExposure'])"
```

Hidden is a config state, not a repo property: change the entry in `mcp.json` if the
tool is genuinely needed (whether that takes effect without restarting pi: unverified),
or ask `ask_wiki_question` instead. Do not re-try a hidden name and report the error as
the dependency's problem.
