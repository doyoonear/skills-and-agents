# Style Guide

**The single source of truth for colors, typography, and tokens.** Every diagram draws from this — not from hex values inlined in other reference files. If you want to change the visual skin of diagram-design, change this file.

Default skin is a neutral editorial palette — warm stone paper, deep charcoal ink, rust accent. It's designed to look good out of the box for any open-source user without matching any specific brand. Swap these values (or run [`onboarding.md`](onboarding.md)) and every new diagram inherits the new skin without touching any type-specific logic.

To generate your own from a website URL, see [`onboarding.md`](onboarding.md).

---

## Tokens

### Semantic roles

Every token is referred to by **semantic role**, not by its hex value. Type references (`type-*.md`) and SKILL.md say `accent`, not `#f7591f`.

| Role | Purpose | Default (light) | Default (dark) |
|---|---|---|---|
| `paper` | Page background, default node fill | `#faf7f2` | `#1c1917` |
| `paper-2` | Diagram container bg, secondary fill | `#f2ede4` | `#292524` |
| `ink` | Primary text, primary stroke | `#1c1917` | `#faf7f2` |
| `muted` | Secondary text, default arrow stroke | `#57534e` | `#a8a29e` |
| `soft` | Sublabels, boundary labels | `#78716c` | `#8e8680` |
| `rule` | Hairline borders | `rgba(28,25,23,0.12)` | `rgba(250,247,242,0.12)` |
| `rule-solid` | Stronger borders, baselines | `rgba(120,113,108,0.25)` | `rgba(168,162,158,0.25)` |
| `accent` | Focal / 1–2 max per diagram | `#b5523a` | `#d6724a` |
| `accent-tint` | Fill for accent-bordered boxes | `rgba(181,82,58,0.08)` | `rgba(214,114,74,0.10)` |
| `link` | HTTP/API calls, external arrows | `#2563eb` | `#60a5fa` |

> **Note:** The pre-baked example HTML files in `assets/` were built under an earlier skin. Regenerating them against the current `style-guide.md` is a v1.1 task. New diagrams the skill produces will use the tokens above.

### Inversion rule (light → dark)

Any `rgba(28,25,23, X)` in light becomes `rgba(250,247,242, X)` in dark. Same opacities, RGB flipped. The accent gets a slight hue-shift brighter to read on dark paper.

---

## Typography

| Role | Family | Size | Weight | Usage |
|---|---|---|---|---|
| `title` | Instrument Serif | 1.75rem | 400 | Page H1 |
| `node-name` | Geist (sans) | 12px | 600 | Human-readable labels |
| `sublabel` | Geist Mono | 9px | 400 | Port, protocol, URL, field type |
| `eyebrow` | Geist Mono | 7–8px | 500, tracked 0.18em, uppercase | Type tags, axis labels |
| `arrow-label` | Geist Mono | 8px | 400, tracked 0.06em | Arrow annotations |
| `callout` | Instrument Serif *italic* | 14px | 400 | Editorial asides only |

### Font stack

```html
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Geist:wght@400;500;600&family=Geist+Mono:wght@400;500;600&display=swap" rel="stylesheet">
```

**Load-bearing rule:** Mono is for *technical* content (ports, commands, URLs, field types). Names go in Geist sans. Page title is Instrument Serif. Italic Instrument Serif is reserved for annotation callouts (see [primitive-annotation.md](primitive-annotation.md)). **Never JetBrains Mono** as a blanket "dev" font.

---

## Stroke, radius, spacing

| Token | Value | Use |
|---|---|---|
| `stroke-thin` | `0.8` | Tag-box outlines, leaf nodes |
| `stroke-default` | `1` | Most strokes |
| `stroke-strong` | `1.2` | Emphasis strokes |
| `radius-sm` | `4` | Small tags |
| `radius-md` | `6` | Node boxes |
| `radius-lg` | `8` | Containers, rings |
| `grid` | `4` | Every coord, size, and gap is divisible by 4 (hard rule) |

---

## Node type → treatment

Semantic role combinations — reference these by name in type specs.

| Type | Fill | Stroke |
|---|---|---|
| `focal` (1–2 max) | `accent-tint` | `accent` |
| `backend` | `#ffffff` (white) | `ink` |
| `store` | `ink @ 0.05` | `muted` |
| `external` | `ink @ 0.03` | `ink @ 0.30` |
| `input` | `muted @ 0.10` | `soft` |
| `optional` | `ink @ 0.02` | `ink @ 0.20` dashed `4,3` |
| `security` | `accent @ 0.05` | `accent @ 0.50` dashed `4,4` |

---

---

## Custom skin — code-complete-2 (hamsurang / 함수랑 산악회)

Onboarded 2026-04-21 from `src/css/custom.css` + `docusaurus.config.ts`. Project: Code Complete 2판 한글 스터디 (Docusaurus 3.9). Diagrams live under `static/diagrams/` and inline into MDX via `<svg>` to pick up Docusaurus theme variables.

### Project tokens (override defaults above for this project)

| Role | Light | Dark | Maps to Docusaurus var |
|---|---|---|---|
| `paper` | `#ffffff` | `#0D1117` | `--ifm-background-color` |
| `paper-2` | `#f6f8fa` | `#161B22` | `--ifm-card-background-color` |
| `ink` | `#1F2328` | `#f0f6fc` | `--ifm-font-color-base` |
| `muted` | `#57534e` | `#a8a29e` | — |
| `soft` | `#78716c` | `#8e8680` | — |
| `rule` | `rgba(31,35,40,0.12)` | `rgba(240,246,252,0.12)` | — |
| `accent` | `#16A34A` | `#4ADE80` | `--ifm-color-primary` |
| `accent-tint` | `rgba(22,163,74,0.08)` | `rgba(74,222,128,0.12)` | — |
| `accent-2` | `#D97706` | `#FCD34D` | `--ham-accent` (amber 강조) |
| `link` | `#2563eb` | `#60a5fa` | — |

### Typography override

| Role | Family | Why |
|---|---|---|
| `title` | Instrument Serif | Kept (title is mostly English) |
| `node-name` | **Noto Sans KR** fallback Geist | Node labels are 90% Korean (챕터명, 에이전트명) |
| `sublabel` | Geist Mono, fallback `ui-monospace` | Technical labels only |
| `callout` | Instrument Serif *italic* | Kept (editorial asides in English allowed) |

### Semantic rules for this project

- **`accent` (green) = coverage / 생존**. Use on "다룬 장", 🟢 판정 focal points, and pipeline's ★ main step. Max 2 focal per diagram.
- **`accent-2` (amber) = attention / hand-off**. Use for *edges* (arrows marking data handoff between agents) — never as a fill, never compete with `accent` for focal status.
- **SVG tokens use CSS variables, not hex.** Diagrams inline into Docusaurus MDX and inherit `--ifm-color-primary` so light/dark switches automatically. Fallback hex for GitHub README rendering.

```css
/* SVG inline pattern */
fill: var(--ifm-color-primary, #16A34A);
stroke: var(--ifm-color-emphasis-700, #1F2328);
```

---

## Customizing the skin

Three options:

1. **Run onboarding** — see [`onboarding.md`](onboarding.md). Drop a URL; the skill extracts the palette + fonts and rewrites this file.
2. **Edit by hand** — change the hex values in the tables above. Run the pre-output taste gate afterward to verify the accent still reads as "focal" against the new paper color.
3. **Brand handoff** — paste your existing design-token JSON into a new section here and map its tokens to the semantic roles above.

### Constraints (don't break these)

- **Contrast**: `ink` must hit WCAG AA on `paper`. `muted` must hit AA on `paper` for 11px+ text.
- **One accent**: pick one color for `accent`. Two accents erases the focal signal.
- **No rainbow palette**: if your brand ships 8 colors, pick 3 (paper, ink, accent). The rest become `muted` variants.
- **Serif + sans + mono**: three families, not more. If brand typography is all sans, keep Instrument Serif for `title` and `callout` anyway — the contrast is load-bearing.
- **Paper is warm-neutral, not pure white**: pure white turns the design sterile. Pick a cream, bone, or light grey with a hint of warmth.
- **Dot pattern survives**: the 22×22 dot pattern on the diagram background needs to sit at ~10% opacity of `ink` on `paper` — verify it's visible but quiet after a skin change.
