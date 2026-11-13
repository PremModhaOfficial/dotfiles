# Tool economy: batch with codemode (detail)

Do not fire independent reads, greps, or lookups one per message. Put them in a
single `codemode` script and return only the extracted fields; never print or
return raw tool output. This applies to `glob`/`grep`/`read_file` batches and to
MCP lookups alike.
