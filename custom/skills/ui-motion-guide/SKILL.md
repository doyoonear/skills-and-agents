---
name: ui-motion-guide
description: |
  UI motion and animation principles guide for web/app interfaces. Covers spring vs easing decision framework, timing/physics rules, AnimatePresence exit patterns, morphing icons, and container bound animations.
  This skill should be used when implementing or reviewing animations, transitions, motion design, or when user mentions "애니메이션", "모션", "spring", "easing", "AnimatePresence", "morphing icon", "컨테이너 애니메이션", "UI 모션", "트랜지션".
  Not for CSS-only patterns (use ui-css-patterns) or sound feedback (use ui-sound-design).
---

# UI Motion Guide

Unified reference for UI motion/animation principles and implementation patterns.
Based on Disney's 12 Principles adapted for digital interfaces, spring/easing physics,
and Motion (Framer Motion) library patterns.

## 12 Principles of Animation (UI Adaptation)

| # | Principle | UI Takeaway |
|---|-----------|-------------|
| 1 | **Squash & Stretch** | Subtle scale deformation (0.95-1.05). Too much = cartoon. |
| 2 | **Anticipation** | Prepare user for next action (button compress before send, pull-to-refresh). |
| 3 | **Staging** | One focal point at a time. Dim backgrounds for modals. Sequence reveals. |
| 4 | **Straight Ahead / Pose to Pose** | Web = pose to pose (keyframes, browser interpolates). Context menus: animate exit only, never entrance. |
| 5 | **Follow Through / Overlapping** | Nothing moves as single rigid unit. Springs add organic overshoot. Stagger ≤50ms/item. |
| 6 | **Slow In & Slow Out** | ease-out for entrances, ease-in for exits, ease-in-out for deliberate moves. |
| 7 | **Arcs** | Curved paths feel organic (Dynamic Island). Reserve for hero moments. |
| 8 | **Secondary Action** | Flourishes supporting main action (sparkle on checkmark). Sound can qualify. |
| 9 | **Timing** | Keep interactions ≤300ms. Be consistent. Define timing scale early. |
| 10 | **Exaggeration** | Amplify for emphasis. Good for onboarding, empty states, errors. Sparingly. |
| 11 | **Solid Drawing** | Shadows = depth, layering = hierarchy. CSS perspective for 3D transforms. |
| 12 | **Appeal** | Sum of all techniques applied with care. |

---

## Spring vs Easing Decision Framework

This is the core decision model. Ask: **"Is this motion reacting to the user, or is the system speaking?"**

```
┌─────────────────────────┬───────────────┬──────────────────────────────────┐
│ Scenario                │ Use           │ Why                              │
├─────────────────────────┼───────────────┼──────────────────────────────────┤
│ Gesture-driven motion   │ Spring        │ Survives interruption,           │
│ (drag, flick, swipe)    │               │ preserves velocity               │
├─────────────────────────┼───────────────┼──────────────────────────────────┤
│ System state change     │ Easing curve  │ Clear start/end, predictable     │
│ (toggle, page swap)     │               │                                  │
├─────────────────────────┼───────────────┼──────────────────────────────────┤
│ Time representation     │ Linear        │ 1:1 time-progress relationship   │
│ (progress, loading bar) │               │                                  │
├─────────────────────────┼───────────────┼──────────────────────────────────┤
│ High-frequency input    │ None          │ Animation adds noise             │
│ (typing, fast toggles)  │               │                                  │
└─────────────────────────┴───────────────┴──────────────────────────────────┘
```

### Easing Curves

Format: `cubic-bezier(x1, y1, x2, y2)` — x1,y1 control responsiveness (how motion begins), x2,y2 control how motion ends.

**Common patterns:**
- **Entrance** (ease-out): `cubic-bezier(0, 0, 0.2, 1)` — snappy arrival
- **Exit** (ease-in): `cubic-bezier(0.4, 0, 1, 1)` — builds momentum leaving
- **In-view transition** (ease-in-out): `cubic-bezier(0.4, 0, 0.2, 1)` — deliberate move
- **Linear**: Only for progress indicators, never for motion

### Spring Parameters

| Parameter | What it controls | Effect |
|-----------|-----------------|--------|
| `stiffness` | How strongly spring pulls toward target | Higher = snappier |
| `damping` | How quickly energy is removed | Higher = less bounce |
| `mass` | How heavy the object feels | Higher = more sluggish |

Key difference: **springs have no predefined end time** (they settle naturally), easing curves do.

**Rule:** Shorten duration first before adjusting the curve. If a curve feels wrong, it's usually too long.

---

## Timing & Duration Rules

| Context | Duration | Rule ID |
|---------|----------|---------|
| Press / hover feedback | 120-180ms | `duration-press-hover` |
| Small state change (toggle, chip) | 180-260ms | `duration-small-state` |
| User-initiated max | 300ms | `duration-max-300ms` |
| Context menu entrance | 0ms (instant) | `none-context-menu-entrance` |
| Keyboard navigation | 0ms (instant) | `none-keyboard-navigation` |

---

## Rules with Examples

### Easing Direction

**`easing-entrance-ease-out`** — Entrances use ease-out (fast start, gentle stop).

```tsx
// FAIL: Linear entrance feels robotic
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2, ease: "linear" }}
/>

// PASS: ease-out entrance feels snappy
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2, ease: [0, 0, 0.2, 1] }}
/>
```

**`easing-exit-ease-in`** — Exits use ease-in (slow start, fast departure).

```tsx
// FAIL: ease-out on exit feels like it's hesitating to leave
<motion.div
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.15, ease: "easeOut" }}
/>

// PASS: ease-in exit builds momentum
<motion.div
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.15, ease: [0.4, 0, 1, 1] }}
/>
```

### Physics & Active States

**`physics-active-state`** — Interactive elements need `:active` / `whileTap` with scale.

```tsx
// FAIL: Button with no press feedback
<motion.button onClick={handleSubmit}>
  Submit
</motion.button>

// PASS: Button with tactile scale response
<motion.button
  onClick={handleSubmit}
  whileTap={{ scale: 0.97 }}
  transition={{ type: "spring", stiffness: 500, damping: 30 }}
>
  Submit
</motion.button>
```

**`physics-subtle-deformation`** — Scale values in 0.95-1.05 range.

```tsx
// FAIL: Exaggerated scale feels cartoonish
whileTap={{ scale: 0.8 }}

// PASS: Subtle deformation
whileTap={{ scale: 0.97 }}
whileHover={{ scale: 1.02 }}
```

**`physics-no-excessive-stagger`** — Stagger delay ≤50ms per item.

```tsx
// FAIL: 200ms stagger makes list feel sluggish
const variants = {
  visible: { transition: { staggerChildren: 0.2 } },
};

// PASS: 30ms stagger feels brisk
const variants = {
  visible: { transition: { staggerChildren: 0.03 } },
};
```

### Spring Usage

**`spring-for-gestures`** — Gesture-driven motion must use springs.

```tsx
// FAIL: Easing for drag (can't preserve velocity on release)
<motion.div
  drag="x"
  animate={{ x: 0 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>

// PASS: Spring survives interruption and preserves velocity
<motion.div
  drag="x"
  animate={{ x: 0 }}
  transition={{ type: "spring", stiffness: 300, damping: 25 }}
/>
```

**`spring-params-balanced`** — Avoid excessive oscillation (high stiffness + low damping).

```tsx
// FAIL: Bounces forever
transition={{ type: "spring", stiffness: 800, damping: 5 }}

// PASS: Controlled overshoot-and-settle
transition={{ type: "spring", stiffness: 300, damping: 25 }}
```

### Staging

**`staging-one-focal-point`** — One prominent animation at a time.

```tsx
// FAIL: Multiple competing animations
<motion.div animate={{ scale: 1.1, rotate: 10 }} />
<motion.div animate={{ x: 100 }} />
<motion.div animate={{ opacity: [0, 1, 0] }} />

// PASS: Single focal animation, others static or subtle
<motion.div animate={{ scale: 1.1 }} />  {/* Hero action */}
<div className="opacity-50" />             {/* Dimmed background */}
```

**`staging-dim-background`** — Dim overlay for modals/dialogs.

```tsx
// PASS: Overlay dims background to direct focus
<motion.div
  className="fixed inset-0 bg-black/40"
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  exit={{ opacity: 0 }}
/>
```

### No-Animation Cases

**`none-high-frequency`** — No animation for high-frequency interactions.

```tsx
// FAIL: Animating every keystroke
<motion.span animate={{ opacity: 1 }} key={inputValue}>
  {inputValue}
</motion.span>

// PASS: Instant update
<span>{inputValue}</span>
```

---

## Accessibility

Always respect `prefers-reduced-motion`:

```tsx
// Global: disable all motion
const MotionConfig = ({ children }) => (
  <LazyMotion features={domAnimation}>
    <MotionConfig reducedMotion="user">{children}</MotionConfig>
  </LazyMotion>
);

// Per-element: provide fallback
const prefersReduced = useReducedMotion();
<motion.div
  animate={{ x: prefersReduced ? 0 : 100, opacity: 1 }}
/>
```

---

## Reference Documents

For detailed implementation patterns, load the relevant reference:

| Reference | Content | When to Load |
|-----------|---------|--------------|
| `references/animate-presence.md` | AnimatePresence exit animations, modes, usePresence, nested exits | Implementing enter/exit transitions, list animations, route transitions |
| `references/morphing-icons.md` | SVG line-based morphing icon system with spring physics | Building animated icon sets, hamburger-to-X transitions |
| `references/container-animation.md` | Animating auto width/height, useMeasure, fluid text | Expanding panels, accordions, dynamic-width buttons, text transitions |

---

## Output Format

When reviewing motion code, report issues as:

```
[RULE_ID] file:line — description

Example:
[easing-entrance-ease-out] components/Modal.tsx:42 — Entrance uses linear easing; should use ease-out
[duration-max-300ms] components/Drawer.tsx:18 — Transition duration is 500ms; reduce to ≤300ms
[spring-for-gestures] components/SwipeCard.tsx:31 — Drag interaction uses easing; switch to spring
```

---

## Quick Reference

```
ENTRANCES:  ease-out    [0, 0, 0.2, 1]        120-300ms
EXITS:      ease-in     [0.4, 0, 1, 1]        120-200ms
IN-VIEW:    ease-in-out [0.4, 0, 0.2, 1]      180-300ms
PROGRESS:   linear      —                      matches real time
GESTURES:   spring      stiffness/damping/mass no fixed duration
PRESS:      spring      stiffness:500 damp:30  whileTap scale:0.97
HIGH-FREQ:  none        —                      instant
STAGGER:    ≤50ms/item  —                      30ms typical
```
