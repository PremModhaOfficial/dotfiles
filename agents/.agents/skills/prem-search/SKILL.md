---
name: prem-search
description: Research that recons first. Before searching, establish the best way to research this Topic at this Time on this Harness, then run that Method. Use only when the user asks how the research should be done, or when the method itself is worth choosing rather than assumed. A plain "research X" belongs to the research skill.
---

# prem-search

Research, but choose the **Method** first. Plain [`research`](../research/SKILL.md) runs a search with the method the agent already assumes; prem-search makes the method the first deliverable, because the right method is a function of three things that change every run: the **Topic**, the **Time**, and the **Harness**.

The words are fixed by [GLOSSARY.md](./GLOSSARY.md). Use them exactly.

## 1. Recon

Dispatch a **background agent**, as `research` does, so you keep working while it reads.

Recon answers one question and never recurses: *what is the best way to research this Topic, at this Time, on this Harness?* It probes three axes, each its own search:

- **Topic probe** - where does authority about this Topic live? Who owns the claims: an official spec, first-party docs, source code, a standards body, a named paper? Name those sources.
- **Time probe** - what is current best practice for researching a Topic like this? Tooling and technique move; find what holds now and prefer the recent primary source over a remembered default.
- **Harness probe** - what can *this* Harness actually do? Inventory the real capabilities here (web search, browser, MCP servers, subagents, background tasks) and their limits, so the Method never assumes a tool that is not present.

Recon is one bounded pass. Research the best way to research once; do not research the best way to research the best way to research.

**Completion criterion**: a written **Method** - the sources to trust, the tools to use, and the order to take - that names the Topic, the Time, and the Harness it was chosen for.

## 2. Execute the Method

Run the Method. Keep `research`'s bar: every **Finding** is verified against the **Primary source** that owns it, never a write-up of it. Follow each claim back to its owner.

**Completion criterion**: every claim in the findings traces to the Primary source that owns it.

## 3. Capture

Write the findings to a single Markdown file, citing each claim's source. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.

Then hand the durable residue to [`domain-modeling`](../domain-modeling/SKILL.md): terms the findings settle go to `GLOSSARY.md`, and decisions that are hard to reverse and surprising without context go to an ADR.

**Completion criterion**: the findings file exists, and every durable term or decision it produced is either written down or explicitly judged not worth recording.
