# Ledger templates and worked example

Load when building the first ledger of a task.

## Coverage table (per component)
| Component | Sources read | Options found | Accounted for | Verdict |
|---|---|---|---|---|
Verdicts: `COMPLETE` (two sources agree, all accounted) · `GAPS` (list, fix) · `SINGLE-SOURCE` (open item). "Accounted for" = has a Done row, a grouped `[N/A]` row, or a Not-done row.

## Done ledger
| Component | Knob | Value | Source | Why |
|---|---|---|---|---|
Source tags (one per row): `[USER]` `[ASKED]` `[VERIFIED: where]` `[ASSUMES: X]` `[N/A]`. "Why" must be specific to this task; "best practice" alone is hollow.

## Not-done ledger
| Item | Kind | Why not | Source | Revisit when |
|---|---|---|---|---|
Kinds: `REJECTED` (weighed, chose against) · `DEFERRED` · `OUT-OF-SCOPE` · `DECLINED` (user said no) · `UNKNOWN` (couldn't determine; open). Source tags as above. "Revisit when" = the trigger that would flip the decision. `[N/A]` = irrelevant; Not-done = relevant or tempting, consciously left.

## Example (fingerprint login)

| Component | Knob | Value | Source | Why |
|---|---|---|---|---|
| PAM fprintd module | timeout | 10s | `[ASKED]` | user wants quick fallback to password |
| PAM fprintd module | max-tries | 3 | `[VERIFIED: man pam_fprintd]` | matches docs default |
| PAM stack | method order | fingerprint `sufficient`, password after | `[ASKED]` | lockout safety |
| Fingerprint daemon | enabled at boot | yes | `[ASSUMES: wants it always on]` | needed after reboot |

| Item | Kind | Why not | Source | Revisit when |
|---|---|---|---|---|
| Fingerprint for sudo | OUT-OF-SCOPE | login only was requested | `[USER]` | wants passwordless sudo |
| Fingerprint-only login | REJECTED | sensor failure would lock user out | `[ASSUMES: no other login path]` | recovery key or second admin exists |
| Third enrolled finger | DEFERRED | two meets the stated need | `[ASKED]` | enrollment failures grow |
