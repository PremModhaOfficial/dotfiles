| # | input | bucket predicted | expected output | actual output | ok |
|---|---|---|---|---|---|
| 1 | `cat "/brag"` | position | `cat "/brag"` | `cat "/brag"` | ok |
| 2 | `cd /brag` | position | `cd /brag` | `cd /brag` | ok |
| 3 | `[x](/brag)` | position | `[x](/brag)` | `[x](/brag)` | ok |
| 4 | `<output-dir>/brag.mp4` | token-suffix | `<output-dir>/brag.mp4` | `<output-dir>/brag.mp4` | ok |
| 5 | `mkdir /brag` | position | `mkdir /brag` | `mkdir /brag` | ok |
| 6 | `vim /brag` | position | `vim /brag` | `vim /brag` | ok |
| 7 | `sort /brag` | position | `sort /brag` | `sort /brag` | ok |
| 8 | `python3 /brag` | position | `python3 /brag` | `python3 /brag` | ok |
| 9 | `dir /brag` | position | `dir /brag` | `dir /brag` | ok |
| 10 | `cat '/brag'` | position | `cat '/brag'` | `cat '/brag'` | ok |
| 11 | `cd "/brag"` | position | `cd "/brag"` | `cd "/brag"` | ok |
| 12 | `- cd /brag` | position | `- cd /brag` | `- cd /brag` | ok |
| 13 | `\|/brag\|` | position | `\|/brag\|` | `\|/brag\|` | ok |
| 14 | `**/brag**` | token-suffix | `**/brag**` | `**/brag**` | ok |
| 15 | `run /brag!` | position | `run /brag!` | `run /brag!` | ok |
| 16 | `- /brag!` | safe-bare | `- /skill:brag!` | `- /skill:brag!` | ok |
| 17 | `* /brag*` | safe-bare | `* /skill:brag*` | `* /skill:brag*` | ok |
| 18 | `Trigger: \|/brag\|` | position | `Trigger: \|/brag\|` | `Trigger: \|/brag\|` | ok |
| 19 | `Trigger:/brag` | safe-bare | `Trigger:/skill:brag` | `Trigger:/skill:brag` | ok |
| 20 | `x /brag-` | name-continues | `x /brag-` | `x /brag-` | ok |
| 21 | `/brag-x` | name-continues | `/brag-x` | `/brag-x` | ok |
| 22 | `then run /brag` | position | `then run /brag` | `then run /brag` | ok |
| 23 | `(run /brag)` | position | `(run /brag)` | `(run /brag)` | ok |
| 24 | `Trigger: see /brag` | position | `Trigger: see /brag` | `Trigger: see /brag` | ok |
| 25 | `/brag.md` | token-suffix | `/brag.md` | `/brag.md` | ok |
| 26 | `/brag/x` | token-suffix | `/brag/x` | `/brag/x` | ok |
| 27 | `/brag@2x.png` | token-suffix | `/brag@2x.png` | `/brag@2x.png` | ok |
| 28 | `/brag?tab=x` | token-suffix | `/brag?tab=x` | `/brag?tab=x` | ok |
| 29 | `/brag#x` | token-suffix | `/brag#x` | `/brag#x` | ok |
| 30 | `/brag{x,y}` | token-suffix | `/brag{x,y}` | `/brag{x,y}` | ok |
| 31 | `/brag,: ` | token-suffix | `/brag,: ` | `/brag,: ` | ok |
| 32 | `/clear` | unknown-name | `/clear` | `/clear` | ok |
| 33 | `/ x` | not-name | `/ x` | `/ x` | ok |
| 34 | `/skill:brag.md` | prefixed-tail | `/skill:brag.md` | `/skill:brag.md` | ok |
| 35 | `/brag` | safe-bare | `/skill:brag` | `/skill:brag` | ok |
| 36 | `    /brag` | safe-bare | `    /skill:brag` | `    /skill:brag` | ok |
| 37 | `/brag --tone chaotic` | safe-bare | `/skill:brag --tone chaotic` | `/skill:brag --tone chaotic` | ok |
| 38 | `/brag!` | safe-bare | `/skill:brag!` | `/skill:brag!` | ok |
| 39 | ``/brag`` | safe-bare | ``/skill:brag`` | ``/skill:brag`` | ok |
| 40 | `- /brag` | safe-bare | `- /skill:brag` | `- /skill:brag` | ok |
| 41 | `* /brag` | safe-bare | `* /skill:brag` | `* /skill:brag` | ok |
| 42 | `+ /brag` | safe-bare | `+ /skill:brag` | `+ /skill:brag` | ok |
| 43 | `  - /brag` | safe-bare | `  - /skill:brag` | `  - /skill:brag` | ok |
| 44 | `### /brag` | safe-bare | `### /skill:brag` | `### /skill:brag` | ok |
| 45 | `1. /brag` | safe-bare | `1. /skill:brag` | `1. /skill:brag` | ok |
| 46 | `12) /brag` | safe-bare | `12) /skill:brag` | `12) /skill:brag` | ok |
| 47 | `-   /brag --x` | safe-bare | `-   /skill:brag --x` | `-   /skill:brag --x` | ok |
| 48 | `Trigger: /brag` | safe-bare | `Trigger: /skill:brag` | `Trigger: /skill:brag` | ok |
| 49 | `Trigger:/brag` | safe-bare | `Trigger:/skill:brag` | `Trigger:/skill:brag` | ok |
| 50 | `Use when:/brag, x` | safe-bare | `Use when:/skill:brag, x` | `Use when:/skill:brag, x` | ok |
| 51 | `  Use for: /brag.` | safe-bare | `  Use for: /skill:brag.` | `  Use for: /skill:brag.` | ok |
| 52 | `Activate: /brag` | safe-bare | `Activate: /skill:brag` | `Activate: /skill:brag` | ok |
| 53 | `Invoke: /brag` | safe-bare | `Invoke: /skill:brag` | `Invoke: /skill:brag` | ok |
| 54 | `description: "Use when: /brag, x"` | safe-bare | `description: "Use when: /skill:brag, x"` | `description: "Use when: /skill:brag, x"` | ok |
| 55 | `use `/brag`` | safe-bare | `use `/skill:brag`` | `use `/skill:brag`` | ok |
| 56 | `say `/brag`.` | safe-bare | `say `/skill:brag`.` | `say `/skill:brag`.` | ok |
| 57 | ``/brag`, `/brag`` | safe-bare | ``/skill:brag`, `/skill:brag`` | ``/skill:brag`, `/skill:brag`` | ok |
| 58 | `/skill:brag` | rewritten | `/skill:brag` | `/skill:brag` | ok |
| 59 | `Trigger: /skill:brag` | rewritten | `Trigger: /skill:brag` | `Trigger: /skill:brag` | ok |

59 rows, 0 failing
