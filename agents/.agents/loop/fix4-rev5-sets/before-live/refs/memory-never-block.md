# Never block: the tool forms (detail)

The rules are inline; these are the calls they name.

- Shell: `run_in_background=true` or `monitor_command`.
- Peek without interrupting: `shell_output` with `from_offset` + `max_chars`.
- One wait: `wait:"exit"` / `wait:"output"`, in its own message.
- Why it matters: a silent wait reads as a stall and earns no progress; a poll
  loop trades one stall for a bigger one.
