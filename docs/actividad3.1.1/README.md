# Activity 3.1.1 — Social engineering with SET

Terminal-HUD slide deck on social-engineering pentesting methods and the
Social-Engineer Toolkit (SET). Open `index.html` in any modern browser.

A persistent ASCII scene runs on a `<canvas>` behind every slide and is redrawn
character by character; the slides are panels over it, and a thin telemetry HUD
(frame, reticle, rulers, live readouts) frames the whole thing. Mostly
monochrome, with one amber reserved for the live indicator and the attack's key
moments.

## Present

| Key | Action |
|---|---|
| `→` `space` | advance (next phase/indicator, then next slide) |
| `←` | back |
| `N` | presenter notes for the current slide |
| `F` | fullscreen |
| `Esc` | close notes |

The URL keeps your place (`index.html#4.3` = slide 4, step 3). On the defense
slide, click **verification: OFF** (or Tab to it and press Enter) to toggle the
wall that stops the attack.

## Slides

1. Cover
2. Five phases of the method (walk with `→`)
3. The tool: what SET is
4. SET's four attack vectors (step with `→`)
5. Simulated case: the urgent password email (step with `→`)
6. One goal, two sides — a reported internal phishing drill vs. SET's
   credential-harvester module
7. Defense: break the channel (toggle)
8. Rules of engagement
9. References (TrustedSec SET repository, TrustedSec site, NIST SP 800-115)

## Content integrity

Every scenario is **synthetic and authorized**. The company *Meridian
Logistics*, the people, domains and the `[to be measured]` click rate are
invented for the exercise. The Mercedes-Benz internal-drill item on slide 6 is
labelled **reported** — an industry practice cited by the source document, not a
claim verified here. The cover lists the five team members and student IDs (from `docs/actividad2/main.typ`) and the professor.

## Files

| File | What it is |
|---|---|
| `index.html` | the deck: HUD chrome, styles, wiring |
| `content.js` | all slide copy (edit text here) |
| `term.js` | ASCII scene renderer + camera-less deck engine |
| `deck.css` | shared slide transitions |
| `mock/`, `mock-ascii/` | earlier exploration (graph version and the five terminal studies); not part of the deliverable |

## Known gaps / not done yet

- **Fonts load from Google Fonts over the network.** For a projector with no
  internet, the face falls back to the system monospace. Self-hosting Geist Mono
  under `fonts/` (as the other decks do) is a follow-up.
- **No multi-page PDF export yet.** Slides are stacked overlays, so a single
  print captures one slide. A print stylesheet that paginates all nine is a
  follow-up; for now present live in fullscreen.
- `[to be measured]` stays until a real authorized exercise produces numbers.
