# Challenge Protocol

Goal: turn each `[ASSUMES: X]` (in the Done or Not-done ledger) and each factual claim in a "Why not" into CONFIRMED / REFUTED / UNVERIFIABLE using evidence, not recall. The same ladder also powers the coverage gate: diff two sources' option lists to find knobs you missed.

## Evidence ladder (stop at first conclusive rung)

1. **Local ground truth.** `man`, `--help`, shipped default config, `strings`/`grep` on the binary or module, running config dump (e.g. `sshd -T`, `nginx -T`, `systemctl show`). Highest trust: it is what is actually installed.
2. **DeepWiki** (`ask_wiki_question`). Upstream repo's indexed wiki. Good for options, defaults, behavior, source-level semantics.
3. **Web search / upstream docs.** For anything not on GitHub or not indexed.

## DeepWiki usage rules

- Needs `owner/repo` on GitHub. Find the repo first (package homepage, `apt show`, `pip show`, web search). Mirrors on GitLab/freedesktop are often NOT indexed.
- Ask narrow, answerable questions naming the exact option:
  - Good: "What does the `timeout` option of pam_fprintd do and what is the default?"
  - Bad: "How do I set up fingerprint login?"
- Query up to 10 repos in one call when an assumption spans components (e.g. `linux-pam/linux-pam` + the module's own repo).
- If the answer says the context lacks the module/option: **that is not a confirmation.** Try the correct repo, then fall back to rung 1 or 3. If still nothing, verdict = UNVERIFIABLE.
- Prefer answers that cite source files or doc pages. A vague answer = weak evidence; corroborate with rung 1.
- Version matters. Defaults change. Check the installed version against what the wiki describes when it affects the answer.

## Verdict record

For each assumption write one line:

`[ASSUMES: <x>] → CONFIRMED|REFUTED|UNVERIFIABLE | evidence: <cmd output / repo+page / URL> | action: <retag / fix value / ask user>`

## Worked example

Assumption: `[ASSUMES: pam_fprintd default timeout is fine]`
1. `man pam_fprintd` → lists `max-tries`, `timeout` (default shown). Local = conclusive. CONFIRMED value, but whether it is *fine* for the user is a preference → move to `[ASKED]`.
2. If man page lacks it: DeepWiki on the module's upstream repo. If "not found in context", try web. If still nothing → UNVERIFIABLE, tell the user.

Note: "default is documented" ≠ "default suits this user". Confirm the fact with evidence, then still ask if the value affects security or UX.

## Coverage cross-check

For each component, collect option lists from two independent sources (man page, shipped default config, `--help`, DeepWiki answer to "list all configuration options of <module>", upstream docs). Diff them. Every option in either list must appear in the ledger as a row, a grouped N/A, or a Not-done item. Leftovers = GAPS. Only one source obtainable = SINGLE-SOURCE (report it, don't call it complete). Measured: asked to list every sshd_config keyword, DeepWiki returned 92 of the 107 top-level directives in the man page (86%) and omitted 15, including UsePAM, Match, Include and PrintLastLog. Treat its list as one source, never the only one.

## Not-done example

Not-done row: `Fingerprint-only login | REJECTED | sensor failure would lock the user out | [ASSUMES: no other login path if sensor fails]`
Challenge: check the PAM stack for a password fallback and whether a TTY login exists. If a fallback exists, the why-not is REFUTED or weakened; reconsider with the user. If confirmed, retag as verified and cite the check.
