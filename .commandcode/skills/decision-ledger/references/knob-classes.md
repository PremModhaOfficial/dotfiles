# Knob classes and miss log

## Contents
1. Generic knob classes (prompts for unknown unknowns)
2. Miss log (grows over time)

## 1. Generic knob classes

Docs enumerate options per component, but some decisions live between components or aren't options at all. For each component, ask whether any of these apply and ledger the answer:

- **Time:** timeouts, retries, backoff, expiry, TTL, cache lifetime
- **Failure:** fallback when it fails, behavior when dependency is missing or slow, lockout and recovery path
- **Persistence:** survives reboot, survives package update, survives config regeneration
- **Access:** who/what is permitted, least privilege, file modes, ownership, secrets storage
- **Limits:** rate, size, concurrency, memory, disk, log rotation
- **Observability:** where logs go, verbosity, how you'd know it's broken
- **Ordering:** precedence among configs, stack order, startup order, what overrides what
- **Scope:** which users, hosts, environments, versions
- **Reversal:** backup, rollback, uninstall residue
- **Omissions:** features left out, alternatives rejected, adjacent components not touched, requests only partly done; each needs a recorded why-not
- **Interaction:** other software that also reads or modifies the same file/service

## 2. Miss log

Format: `- <task> | missed: <knob or unrecorded omission> | cause: <why process missed it> | fix: <what to do next time>`

- fingerprint login | missed: PAM fprintd timeout and max-tries | cause: agent stopped when login worked, never read the module's option list | fix: Phase 2 reads `man pam_fprintd`; "Time" and "Failure" classes prompt for timeout and fallback
- decision-ledger skill v5 | missed: narration/pitch lines in its own intro | cause: audited structure and size, never ran a line-by-line check of what each line changes; kept "reasons" without testing they change behavior | fix: Phase 6 deletion test on every written line
- coverage_diff.py v1 | missed: 14 of 29 seeded gaps and raised 73 false positives on a real man page | cause: patterns tuned on a synthetic sample and ledger matched by substring | fix: tested on real sshd_config and curl output, whole-token matching, man-style own-line pattern
