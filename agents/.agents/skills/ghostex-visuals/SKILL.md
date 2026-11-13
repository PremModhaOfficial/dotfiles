---
name: ghostex-visuals
description: "Show charts, stat tiles, tables and text layouts inline in the Ghostex chat, ask questions as a form, and publish self-contained HTML pages with `ghostex show`. Use only when the user asks for $ghostex-visuals."
disable-model-invocation: true
---

> **Availability gate:** inert on this host — every `ghostex`/`gx` command below needs the Ghostex runtime at `/opt/ghostex` (`/opt/ghostex/gxserver/bin/ghostex`), which is missing (the PATH stubs fail with `No such file or directory`); install Ghostex Desktop, which unpacks `gxserver` into `/opt/ghostex`, then run these commands from a Ghostex session.

# ghostex-visuals

Ghostex draws a fenced ```visual block in your reply natively, inline in the
chat, on desktop, web and phone.

- Prefer a block for charts, tables, stats and text layouts.
- Ask questions in a ```questions block: the chat shows them as a form.
- Use an HTML page only for what a block cannot express: UI mockups, small
  interactive tools, and questions the reader can only answer by seeing a
  picture.
- Don't restate in prose what the visual already shows. Add only what it
  doesn't: the conclusion, a caveat, the next step.

## Visual blocks

One JSON object in a fence whose info string is `visual`. The block is one of:

- **A Vega-Lite spec** at the top level: an object with `"mark"`. It may have
  `"title"` and `"height"`.
- **A composition**: `{"title"?: "…", "rows": [part, …]}`, drawn top to
  bottom. A part is one of the following, and every part may have `"title"`:
  - `{"chart": <Vega-Lite spec>}`
  - `{"stats": [{"label": "…", "value": "…", "note"?: "…", "tone"?: "good" | "bad" | "neutral"}]}`
    (`value` may be a number)
  - `{"table": {"columns": ["…", …], "rows": [["…", …], …]}}`, or rows as
    objects keyed by column name (then `"columns"` is optional)
  - `{"text": "…"}`
  - `{"columns": [part, …]}`: parts side by side
- **A page**: `{"page": {"title": "…", "url": "…"}}`. Only ever paste this from
  `ghostex show` output (below); never write one yourself.

### The Vega-Lite subset

- `mark`: `bar`, `line`, `area`, `point` (also `circle`, `square`), `arc` (pie;
  `{"type": "arc", "innerRadius": 50}` for a donut). The object form
  `{"type": "line", "point": true}` adds points to a line.
- Encoding channels: `x`, `y`, `color`, `theta`, `tooltip`, `xOffset` (grouped
  bars).
- Field definition keys: `field`, `type` (`quantitative`, `nominal`,
  `ordinal`, `temporal`), `aggregate` (`sum`, `mean`, `count`, `min`, `max`,
  `median`), `title`, `sort` (`"ascending"`, `"descending"`, `null` for data
  order, or an array of values), `axis` (`null` to hide it, or
  `{"title": …}`), `scale` (`{"domain": [min, max], "zero": false}`), `stack`
  (`null`/`false`, `true`, `"normalize"`).
- Data only as `"data": {"values": [ … ]}` with the rows inlined; `data.url`
  isn't supported. Aggregate large data before writing the block.
- Not supported: `layer`, `facet`, `repeat`, `concat`, `transform`,
  `params`/selections, `bin`, and the `rule`, `text`, `tick` and `rect` marks.
  Compute bins, totals or moving averages into the rows yourself.
- The width always fits the chat column; `"height"` sets the chart height
  (100 to 600).

### Check the block before replying

Write the JSON to a temporary file and draw it:

```bash
ghostex visual check /tmp/block.json              # prints a PNG path, or names the problem
ghostex visual check /tmp/block.json --light      # light theme
ghostex visual check /tmp/block.json --width 360  # phone width
```

Look at the PNG, fix what reads badly, then paste the same JSON into your
reply. If `ghostex visual` is an unknown command, this Ghostex is too old to
check: skip the check.

### Examples

Grouped bars:

```visual
{
  "title": "Build time by platform",
  "mark": "bar",
  "height": 220,
  "data": {"values": [
    {"platform": "macOS", "build": "debug", "minutes": 4.2},
    {"platform": "macOS", "build": "release", "minutes": 9.8},
    {"platform": "Windows", "build": "debug", "minutes": 5.1},
    {"platform": "Windows", "build": "release", "minutes": 12.4},
    {"platform": "Linux", "build": "debug", "minutes": 3.6},
    {"platform": "Linux", "build": "release", "minutes": 8.9}
  ]},
  "encoding": {
    "x": {"field": "platform", "type": "nominal", "sort": null, "axis": {"title": null}},
    "xOffset": {"field": "build"},
    "y": {"field": "minutes", "type": "quantitative", "title": "Minutes"},
    "color": {"field": "build", "type": "nominal", "title": "Build"}
  }
}
```

For stacked bars, drop `xOffset`; bars that share an `x` stack by `color`.

A line chart with two series:

```visual
{
  "title": "Response time",
  "mark": {"type": "line", "point": true},
  "data": {"values": [
    {"day": "2026-10-01", "series": "p50", "ms": 120},
    {"day": "2026-10-02", "series": "p50", "ms": 118},
    {"day": "2026-10-03", "series": "p50", "ms": 131},
    {"day": "2026-10-01", "series": "p95", "ms": 340},
    {"day": "2026-10-02", "series": "p95", "ms": 310},
    {"day": "2026-10-03", "series": "p95", "ms": 365}
  ]},
  "encoding": {
    "x": {"field": "day", "type": "temporal", "title": "Day"},
    "y": {"field": "ms", "type": "quantitative", "title": "Milliseconds"},
    "color": {"field": "series", "type": "nominal", "title": "Percentile"},
    "tooltip": [{"field": "day", "type": "temporal"}, {"field": "ms", "type": "quantitative"}]
  }
}
```

Stats above a table:

```visual
{
  "title": "Test run",
  "rows": [
    {"stats": [
      {"label": "Passed", "value": 412, "tone": "good"},
      {"label": "Failed", "value": 3, "note": "all in sync/", "tone": "bad"},
      {"label": "Duration", "value": "2m 41s"}
    ]},
    {"title": "Failures", "table": {
      "columns": ["Test", "Error"],
      "rows": [
        ["sync::resume_after_sleep", "timed out after 30s"],
        ["sync::merge_conflict", "expected 2 rows, got 3"],
        ["sync::large_file", "permission denied"]
      ]
    }}
  ]
}
```

## Questions

When you need the reader's decisions, put the questions in a ```questions
block in your reply. The chat draws it as a form under your message, on
desktop, web and phone: every question at once, choices picked with a click,
a note box per question, and one Send button. Use it instead of asking in
prose or as a numbered list, and instead of your agent's own question tool
(AskUserQuestion and the like), which shows one question at a time. Only when
the reader has to see something to answer (a UI mockup, a layout, a diagram)
use a question page instead (see "Question pages" below).

First run `ghostex visual --help`: if it doesn't mention ```questions, this
Ghostex can't show the form, so ask in prose instead.

```questions
{
  "title": "Settings redesign",
  "questions": [
    {"tag": "Q1", "title": "Which layout should I build?",
     "detail": "Why it matters, in a sentence or two.",
     "choices": [
       {"label": "Tabs", "detail": "One page per area.", "value": "tabs", "recommended": true},
       {"label": "One long page", "value": "one page"}
     ]},
    {"title": "Which platforms first?", "multiple": true, "choices": ["macOS", "Windows", "Phone"]},
    {"title": "What should the new page be called?", "type": "text"}
  ]
}
```

- `title` heads the form ("Questions" when left out); `submit` renames the
  button ("Send answers").
- Each question: `title`; `detail`, a short explanation; `tag`, an optional
  short label such as an issue id; `name`, the answer's key (the title when
  there is none); `multiple` for several picks; `type: "text"` for a text box
  instead of choices (`placeholder` sets its hint). At most 20 questions.
- Each choice is its text, or `{"label", "detail", "value", "recommended"}`:
  `value` is what you receive (the label when there is none) and
  `recommended` adds a Recommended badge. At most 26 choices.
- Write only the questions. The chat letters the choices, ends every choice
  question with "Other / none of these" and a note box, and adds the Send
  button. Nothing is ever preselected (a pick clicked again clears). Newer
  Ghostex versions send a question left blank as `"skipped"` (older ones as
  `null`). Don't add your own "Other" choice.
  A form of two or more questions also ends with a notes box for anything
  else, so don't add your own "Anything else?" question either. Newer Ghostex
  versions also have a Skip all button; a question the reader leaves blank
  arrives as `"skipped"`. Don't add your own Skip choice.
- Check the block before replying: `ghostex visual check /tmp/questions.json`
  lists the questions and their answer keys, or names the problem.
- Give questions a `tag` and refer to them by it in your replies ("Q3 is still
  open"): newer Ghostex versions turn the tag into a link to the form, and a
  "Previous question" pill steps through the questions still waiting for an
  answer.
- A question that no longer matters should stop counting as unanswered. Asking
  every tag of an earlier form again, in a later form or page, replaces it. To
  drop tags without asking anything, write a block with only `withdraw`; it
  also works beside new questions. When the user answers a question another way
  (in the chat, in another form or page, or by doing what it asked), withdraw
  its tag in your next block instead of asking it again:

  ```questions
  {"withdraw": ["Q3", "Q4"]}
  ```

  Only when `ghostex visual --help` mentions `withdraw`: older Ghostex
  versions show this block as an error.
- Put one form in a reply and end your turn. Don't poll or wait in a loop: the
  answers arrive as the next user message, in the same envelope a question
  page uses, and the form then reads Answered. A note arrives under the
  question's key plus ` (note)`, and the form's notes box, when filled in,
  arrives last as `"Additional notes"`. A skipped question arrives as
  `"skipped"`: move on, and don't ask it again unless it blocks the work:

  ```text
  <ghostex-page-answers page="5f0c…" title="Settings redesign">
  {
    "Which layout should I build?": "tabs",
    "Which layout should I build? (note)": "keep search at the top",
    "Which platforms first?": ["macOS", "Other / none of these"],
    "Which platforms first? (note)": "Linux too",
    "What should the new page be called?": null,
    "Which color scheme?": "skipped",
    "Additional notes": "ship macOS first, the rest can wait"
  }
  </ghostex-page-answers>
  ```

## HTML pages

For a mockup or a small interactive tool:

1. Write **one self-contained HTML file**: inline CSS and JS. Libraries from an
   https CDN load fine. Local images are embedded automatically, by absolute
   path (`<img src="/Users/me/shot.png">`, `url(C:/shots/a.png)`) or, from
   Ghostex 10.23, by a path relative to the HTML file (`<img src="img/a.png">`,
   `srcset`, CSS `url(img/a.png)`). On older versions use absolute paths.
   `ghostex show` refuses a page whose local images are missing or not images
   and names them; fix those paths. The finished page, images included, can be
   up to 8 MiB (older versions also cap the HTML file itself at 512 KiB).
   Every other request must be https.
2. Style it with the theme variables Ghostex adds, so it matches the app in
   dark and light: `--background`, `--foreground`, `--muted-foreground`,
   `--border`, `--card`, `--primary` (accent color), `--accent` (hover and
   selected surfaces), `--chart-1` … `--chart-6`, `--radius`, `--font-sans`,
   `--font-mono`. The page body already has the theme's background, text color
   and font.
3. The page runs in a sandbox with no origin of its own: `localStorage`,
   cookies and requests to `http://` or `localhost` don't work. Keep state in
   memory. The one way back to you is the reader's answers (below).
4. Publish it:

   ```bash
   ghostex show page.html --title "Settings mockup"
   ```

5. Paste the ```visual block it prints into your reply exactly as printed.
   The chat shows it as a card for your page. The block carries
   `"open": "popup"`, the floating mark: clicking the card opens the page in a
   floating window over the chat (desktop), which closes when the reader
   clicks away. Leave the mark in for mockups and tools the reader looks at
   and dismisses. Publish with `--browser` after the file name (or remove the
   mark) when the page is better read in a full browser tab, such as a long
   report. Older Ghostex versions print the block without `"open"`: their
   cards open the page in the browser, and they ignore `--browser`.

If `ghostex show` is an unknown command, say this Ghostex is too old to show
pages and give the HTML file's path instead.

### Question pages

Only for questions the reader can answer by seeing something: two layouts to
choose between, a mockup to react to, a diagram to mark up. Plain questions go
in a ```questions block (above). Write the page with the question kit every
page has. First run `ghostex show help`: if it doesn't mention
`gx-questions`, this Ghostex can't take answers from a page, so ask in the
chat instead.

```html
<gx-questions submit="Send to the agent">
  <h1>Settings redesign</h1>
  <gx-wide>
    <!-- layouts A and B, side by side -->
  </gx-wide>
  <gx-question tag="Q1" title="Which layout should I build?">
    <p>Why it matters, in a sentence or two.</p>
    <gx-choice value="tabs" recommended>Layout A: tabs<small>One page per area.</small></gx-choice>
    <gx-choice value="one page">Layout B: one long page</gx-choice>
  </gx-question>
  <gx-wide>
    <!-- the two header styles, side by side -->
  </gx-wide>
  <gx-question tag="Q2" title="Which header style?">
    <gx-choice>Compact</gx-choice>
    <gx-choice>Large title</gx-choice>
  </gx-question>
  <gx-question title="Anything else?" type="text"></gx-question>
</gx-questions>
```

- Put the whole page in one `<gx-questions>`. Its children sit in a centered
  720px column. A `<gx-wide>` child spans the page's full width: put mockups
  there and refer to them from the questions ("Layout A above"). Never put a
  mockup inside a question.
- Each question sits directly below the visual it asks about: a mockup, then
  its question, then the next mockup and its question, so the reader answers
  while the picture is still on screen instead of scrolling back up. When one
  question compares several variants, put them side by side (or stacked)
  immediately above that question, with nothing in between, and keep them
  compact enough to be seen together with it: show one theme with a
  dark/light switch rather than every variant twice. Never collect all the
  mockups first and all the questions at the end.
- Tie each variant to its choice so the reader can pick it right there: wrap
  the variant's title and its mockup in one element with `data-question`
  (the question's `name`, title or tag) and `data-choice` (the choice's
  value, label or letter), for example
  `<section data-question="Q1" data-choice="tabs"><h3>A. Tabs</h3>…</section>`.
  The kit puts a Pick button by that title, shows the variant picked there
  and in the question (clicking either clears both), and adds a note box
  under the mockup whose text arrives as `"<question key> · <choice> (note)"`.
  Older Ghostex versions ignore the attributes; the question still works.
- `<gx-question>`: `title`; `tag`, an optional short label such as an issue
  id; `name`, the answer's key (the title when there is none); `multiple`
  for several picks; `type="text"` for a text box instead of choices. Content
  before its choices, such as a `<p>`, explains the question.
- `<gx-choice>`: its text is the choice and a `<small>` inside is a one-line
  detail. `value` is what you receive (the text without the `<small>` when
  there is none). `recommended` adds a Recommended badge.
- Write only that markup. The kit letters the choices, ends every choice
  question with "Other / none of these" and a note box, and adds the send
  button. Nothing is ever preselected (the reader can also click a pick again
  to clear it), and a question left blank arrives as `"skipped"` (`null` in older
  Ghostex versions). Don't write your
  own form, button, "Other" choice or note box. Newer Ghostex versions also add
  a Skip all button; a skipped question arrives as `"skipped"`.
- Once sent, the page is locked; opening it again shows the answers and an
  Answered note.
- Paste the block exactly as `ghostex show` printed it: for a question page it
  lists the page's tags (`"questions": ["Q1", "Q2"]`), which is how the chat
  counts the page as unanswered and links its tags.
- After pasting the card, end your turn. Don't poll or wait in a loop: the
  answers arrive as the next user message, which the chat shows as an answers
  card while the page's card reads Answered. A note arrives under the
  question's key plus ` (note)`:

  ```text
  <ghostex-page-answers page="7ea5c5be1f2d68ebc9e40f790db0ef29" title="Settings redesign">
  {
    "Which layout should I build?": "tabs",
    "Which layout should I build? (note)": "keep search at the top",
    "Which platforms first?": ["macOS", "Other / none of these"],
    "Which platforms first? (note)": "Linux too",
    "Anything else?": null
  }
  </ghostex-page-answers>
  ```

For an answer the kit can't ask for, such as a ranking or a spot on a
mockup, a page can send its own: `ghostex.submit(answers)` posts any JSON
under 64 KiB and returns a promise that rejects with an `Error` saying why it
wasn't sent; `ghostex.answered` and `ghostex.answers` tell a reopened page what
was sent; an element with `data-gx-answered` is where the Answered note goes.
A page takes one set of answers either way.

What the reader picks and types is kept until they send, also when they close
and reopen the page: the kit's picks and the value of every named `input`,
`textarea` and `select` are saved and filled back in on their own. For other
state (a ranking, marks on a mockup), call `ghostex.saveDraft(value)` with any
JSON as it changes and read it back from `ghostex.draft` when the page loads;
check `ghostex.saveDraft` exists first, since older Ghostex versions lack it.
