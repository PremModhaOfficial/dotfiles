# Code lookup: command forms (detail)

Only the forms; the rules are inline. `graft` is not installed on every machine —
check it is on PATH before using any line below.

- `graft skeleton <file>` — a file's API in ~200 tokens.
- `graft ask "<question>" --source` — locate and understand.
- `graft grep "<literal>"` — every occurrence.
- `graft callers <sym> --depth 2` — blast radius before a signature change.
- `graft map` — orient in an unfamiliar repo.
- deepwiki `ask_wiki_question` — `repoName: "nats-io/nats.rs"`, then the
  question; answers API questions grounded in the repo wiki. One call returned
  every stream, consumer and KV signature that minutes of grepping had missed.
  `read_wiki_structure` first, only when you do not know what to ask.
