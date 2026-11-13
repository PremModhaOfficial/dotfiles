# Never block: the tool forms (detail)

The rule is inline; these are each harness's names for it. A harness not listed
has no wait tool: end the turn, and the next message is the signal.

- commandcode: shell `run_in_background=true` or `monitor_command`; peek `shell_output` with `from_offset` + `max_chars`; wait forms `wait:"exit"` / `wait:"output"`.
- pi: shell `bash` with `nohup <cmd> > <log> 2>&1 &`; peek `bash` with `tail -n 20 <log>`; has no wait tool.

Why it matters: a silent wait reads as a stall and earns no progress; a poll loop
trades one stall for a bigger one.
