---
name: linking-t3-prs
description: Link and watch pull requests from T3 Code. Use when a PR is opened, taken over, pushed, or a merge waits on checks.
---

# T3 PRs

- Link every PR you open, take over, or push with `link_pull_request` or `link_pull_requests`, full URL, as the next call. For a stack of PRs, link every layer you opened or pushed.
- After `watch_pull_request`, end your turn. Do not call it again on a wake; read state instead. A wake is not a merge decision.
- A child never watches or polls. It returns PR URL, head SHA, and check/review state to the parent.
