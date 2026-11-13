# Never block: the tool forms (detail)

The rule is inline; these are each harness's names for it. Wait on the event with
the harness's own wait call. Only a harness with no wait call at all ends the turn
and lets the next message be the signal.

- commandcode: shell `run_in_background=true` or `monitor_command`; peek `shell_output` with `from_offset` + `max_chars`; wait forms `wait:"exit"` / `wait:"output"`.
- pi: shell `bash` with `nohup <cmd> > <log> 2>&1 &`; peek `bash` with `tail -n 20 <log>`;
  wait `hc wait <name>` (it returns when the agent stops working). Every `bash` call
  is capped at 600s by `bash-guard`, so a wait longer than that is either several
  `hc wait` calls or a background log plus a peek. `hc wait` is the one blocking
  call allowed, because the cap bounds it; `intercom ask` is not a wait form.

Why it matters: a silent wait reads as a stall and earns no progress; a poll loop
trades one stall for a bigger one.
