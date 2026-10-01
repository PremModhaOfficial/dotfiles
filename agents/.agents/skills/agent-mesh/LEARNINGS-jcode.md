# Driving jcode headlessly

## Working invocation

    jcode run -p <provider> -m <model> -C <dir> "<message>"

Verified working on this machine:

    jcode run -p openrouter -m stealth/space-bunny-alpha -C "$PWD" "<message>"

Flags that matter:
  --json      machine-readable result instead of streamed text
  --ndjson    newline-delimited events while streaming
  -C/--cwd    working directory
  -p/--provider
  -m/--model  model id, names come from `jcode model list -p <provider>`

## The trap that cost five round trips

`jcode auth status` reports a provider as `available` when the CREDENTIAL is
present. It is a presence check, not a balance check. Providers showing
`available` here all returned HTTP 402 on an actual run:

  jcode        402 $10 activation checkout required
  openrouter   402 "This account never purchased credits"  (default model)
  opencode     402 "Insufficient account funds"
  deepseek     402 "Insufficient Balance"

Openrouter has no credits for its PAID models but the free
`stealth/space-bunny-alpha` routes fine. Always pass `-m` explicitly; the
default model is a paid one and will 402.

Available providers on this box: jcode, openrouter, opencode, deepseek, ollama
(ollama is not currently running).

## Sub-commands

serve, connect, run, repl, acp, self-dev, api-bridge, session, login,
provider-doctor, provider-test-coverage, auth-test, usage, model list,
transcript, replay.
