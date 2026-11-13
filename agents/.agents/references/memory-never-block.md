# Never block: the tool forms (detail)

The rule is inline; these are each harness's names for it.

## The one legal move, and its real cap

- `hc wait <t>` — returns when that terminal stops working. **Default cap 180 s**:
  `hc wait --help` says `--timeout` defaults to config `wait_timeout`, else 180. It
  does not kill the job, so a 180 s return means "still running", not "failed".
  `hc wait <t> --timeout 600` only when one longer wait can finish the job.
- A `bash` call is capped separately at 600 s (`extensions/bash-guard.ts`). So 600 s is
  the ceiling of one `bash` call; **180 s is the ceiling of one `hc wait`.** A wait that
  needs more is another `hc wait` next turn, not a loop inside one turn.
- It prints JSON: `{"ended":true,"exit_code":0,…}`. Assert those fields — "the screen
  looks done" is not a result.

## A job you cannot `hc wait`, without polling

`hc wait` needs a terminal; a `nohup` job started from `bash` has none.

1. Prefer not to create that job. Long work gets its own terminal:
   `hc run --bg --name it3 '<cmd>'` prints the address, and later `hc wait it3` is legal.
2. If it must be `nohup`, the one legal move is a call that blocks on the process and
   cannot loop:

   ```bash
   timeout 170 tail -q -f --pid=$PID <log>   # returns when PID exits, or at 170 s
   ```

   Read what it printed. If it hits 170 s the job is still running: say so in one line
   and end the turn. A `nohup` job emits no event, so the next message is the signal;
   the only reason to touch it again is one more `tail -q -f --pid`.
3. Put `$!` and the log path in your reply, so the resume command is one line.

Never: repeated `sleep N; ps -p`, a `while` re-poll, or a timer. Those are the poll loop
this file bans, and they are slower than the one bounded wait above.

## Peek forms — once, to report

- commandcode: launch `run_in_background=true` or `monitor_command`; peek `shell_output`
  with `from_offset` + `max_chars`; wait `wait:"exit"` / `wait:"output"`.
- pi, an `hc` terminal: `hc read <name> --lines 20`.
- pi, a `nohup` job: `tail -n 20 <log>` (once, to report — not as a wait).
- pi: `hc wait` and `hc read` take a terminal name or address; `hc ls` lists them and
  prints raw JSON (`hc list` is not a subcommand).

`intercom ask` is not a wait form: it blocks on another agent's reply with no cap.

Why it matters: a silent wait reads as a stall and earns no progress; a poll loop trades
one stall for a bigger one.
