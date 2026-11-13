# Web access: command forms (detail)

`oc` (only-cli, installed globally): `oc open <url>` returns a compact numbered
view in a few hundred tokens, then `oc do <n>`, `oc find <query>`, `oc read <n>`,
`oc next`, `oc raw [url]`. Shortcuts skip URL guessing:
`oc gh repo only-cli oc`, `oc hn top`; `oc sites` lists them.

Denied-fetch fallback: use whatever fetch MCP server that harness has configured.
commandcode wires `donsetch` (`mcp__donsetch__web_search`, `web_fetch`, `web_crawl`);
pi configures none of them (its only MCP server is deepwiki, which is repo Q&A).
So in pi: say the built-in call was denied, say no fetch server is configured, and
stop — do not retry the denied tool and do not invent a server name.
