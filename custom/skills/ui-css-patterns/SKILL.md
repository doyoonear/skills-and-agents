---
name: ui-css-patterns
description: |
  CSS patterns for UI animation, pseudo-elements, and view transitions. Covers ::before/::after decorative patterns, hit target expansion, button hover effects, native pseudo-element styling, and the View Transitions API.
  This skill should be used when implementing CSS pseudo-elements, hover effects, hit target expansion, view transitions, or styling native elements like ::backdrop, ::placeholder, ::selection, or when user mentions "CSS 패턴", "가상 요소", "hover 효과", "view transition", "뷰 전환".
  Not for JavaScript-driven animations (use ui-motion-guide) or sound design (use ui-sound-design).
---

# UI CSS Patterns

CSS patterns for pseudo-elements, animations, and transitions in mobile/desktop app development.

## ::before & ::after Pseudo-Elements

### Rule: `pseudo-content-required`

`::before` and `::after` require the `content` property to render, even if empty.

**Fail:**

```css
.element::before {
  width: 20px;
  height: 20px;
  background: red;
}
```

**Pass:**

```css
.element::before {
  content: "";
  width: 20px;
  height: 20px;
  background: red;
}
```

### Rule: `pseudo-over-dom-node`

Use pseudo-elements for decorative content instead of adding extra DOM nodes.

**Fail:**

```tsx
<button className="btn">
  <span className="btn-bg" /> {/* extra DOM node for decoration */}
  Click me
</button>
```

**Pass:**

```tsx
<button className="btn">
  Click me
</button>
```

```css
.btn {
  position: relative;
}

.btn::before {
  content: "";
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.05);
  border-radius: inherit;
  opacity: 0;
  transition: opacity 150ms ease;
}

.btn:hover::before {
  opacity: 1;
}
```

### Rule: `pseudo-position-relative-parent`

Parent must have `position: relative` for absolutely positioned pseudo-elements.

**Fail:**

```css
.card::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: blue;
}
```

**Pass:**

```css
.card {
  position: relative;
}

.card::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: blue;
}
```

### Rule: `pseudo-z-index-layering`

Pseudo-elements need `z-index` for correct layering. Use `z-index: -1` to place behind content.

**Fail:**

```css
.btn {
  position: relative;
}

.btn::before {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border-radius: inherit;
  /* Covers the button text */
}
```

**Pass:**

```css
.btn {
  position: relative;
  isolation: isolate;
}

.btn::before {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border-radius: inherit;
  z-index: -1;
}
```

> `isolation: isolate` on the parent creates a new stacking context, ensuring `z-index: -1` only goes behind the parent's content, not behind the parent itself.

### Rule: `pseudo-hit-target-expansion`

Use negative `inset` values on pseudo-elements to expand hit/touch targets without changing visual size.

**Fail:**

```css
.icon-btn {
  width: 24px;
  height: 24px;
  /* Touch target too small (minimum 44x44px recommended) */
}
```

**Pass:**

```css
.icon-btn {
  position: relative;
  width: 24px;
  height: 24px;
}

.icon-btn::before {
  content: "";
  position: absolute;
  inset: -10px -10px;
  /* Expands touch area to 44x44px without changing visual size */
}
```

For rectangular buttons needing wider horizontal touch targets:

```css
.pill-btn::before {
  content: "";
  position: absolute;
  inset: -8px -12px;
}
```

## Button Hover Effect Pattern

A complete pattern combining the pseudo-element rules above for a polished button hover effect.

```css
.btn-hover {
  position: relative;
  isolation: isolate;
  overflow: hidden;
}

.btn-hover::before {
  content: "";
  position: absolute;
  inset: 0;
  background: currentColor;
  opacity: 0;
  border-radius: inherit;
  transform: scale(0.95);
  transition: opacity 150ms ease, transform 150ms ease;
  z-index: -1;
}

.btn-hover:hover::before {
  opacity: 0.08;
  transform: scale(1);
}

.btn-hover:active::before {
  opacity: 0.12;
  transform: scale(0.98);
}
```

### Tailwind CSS Equivalent

```html
<button class="relative isolate overflow-hidden
  before:content-[''] before:absolute before:inset-0
  before:bg-current before:opacity-0 before:rounded-[inherit]
  before:scale-95 before:transition-all before:-z-10
  hover:before:opacity-[0.08] hover:before:scale-100
  active:before:opacity-[0.12] active:before:scale-[0.98]">
  Button Text
</button>
```

## Separator / Divider Pattern

Use pseudo-elements for visual separators between items instead of `<hr>` or `<div>` nodes.

**Fail:**

```tsx
<ul>
  {items.map((item, i) => (
    <>
      <li key={item.id}>{item.name}</li>
      {i < items.length - 1 && <hr className="divider" />}
    </>
  ))}
</ul>
```

**Pass:**

```tsx
<ul className="divided-list">
  {items.map((item) => (
    <li key={item.id}>{item.name}</li>
  ))}
</ul>
```

```css
.divided-list > li + li {
  position: relative;
}

.divided-list > li + li::before {
  content: "";
  position: absolute;
  top: 0;
  left: 16px;
  right: 16px;
  height: 1px;
  background: var(--color-border, #e5e7eb);
}
```

## Native Pseudo-Element Styling

### Rule: `native-backdrop-styling`

Use `::backdrop` for dialog and popover backgrounds instead of creating overlay div elements.

**Fail:**

```tsx
<div className="overlay" onClick={onClose} /> {/* extra overlay div */}
<dialog open>
  <p>Dialog content</p>
</dialog>
```

**Pass:**

```tsx
<dialog ref={dialogRef}>
  <p>Dialog content</p>
</dialog>
```

```css
dialog::backdrop {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}
```

> `::backdrop` works with both `<dialog>` and Popover API elements. It is rendered by the browser automatically when the dialog is shown via `.showModal()`.

### Rule: `native-placeholder-styling`

Use `::placeholder` for input placeholder styling.

```css
input::placeholder {
  color: #9ca3af;
  font-style: italic;
}
```

### Rule: `native-selection-styling`

Use `::selection` for text selection styling.

```css
::selection {
  background: #3b82f6;
  color: white;
}
```

## View Transitions API

Prefer the View Transitions API over JavaScript animation libraries for page/element transitions.

### Rule: `transition-over-js-library`

**Fail:**

```tsx
import { motion, AnimatePresence } from "framer-motion";

function App() {
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={location.pathname}
        initial={{ opacity: 0, x: 100 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: -100 }}
      >
        <Outlet />
      </motion.div>
    </AnimatePresence>
  );
}
```

**Pass:**

```tsx
function App() {
  const navigate = useNavigate();

  const handleNavigate = (path: string) => {
    if (!document.startViewTransition) {
      navigate(path);
      return;
    }
    document.startViewTransition(() => {
      navigate(path);
    });
  };

  return <Outlet />;
}
```

> Framer Motion or similar libraries are still appropriate for complex in-page micro-interactions (spring physics, gesture-driven animations, layout animations). Use View Transitions API for **page-level transitions** and **shared element transitions**.

### Rule: `transition-name-required`

Elements need `view-transition-name` to participate in transitions.

```css
.hero-image {
  view-transition-name: hero;
}
```

### Rule: `transition-name-unique`

Names must be unique on the page during a transition. Remove from source, add to target.

**Fail:**

```tsx
{/* Both rendered at same time with same name */}
<img style={{ viewTransitionName: "photo" }} src={thumb} />
<img style={{ viewTransitionName: "photo" }} src={full} />
```

**Pass:**

```tsx
<img
  style={{ viewTransitionName: selected ? undefined : `photo-${id}` }}
  src={thumb}
/>
{selected && (
  <img
    style={{ viewTransitionName: `photo-${id}` }}
    src={full}
  />
)}
```

### Rule: `transition-name-cleanup`

Remove transition names after the transition completes.

```typescript
const transition = document.startViewTransition(() => {
  sourceEl.style.viewTransitionName = "";
  targetEl.style.viewTransitionName = name;
});

transition.finished.then(() => {
  targetEl.style.viewTransitionName = "";
});
```

### Rule: `transition-style-pseudo-elements`

Style transitions using the generated pseudo-element tree.

```css
::view-transition-group(hero) {
  animation-duration: 300ms;
  animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

::view-transition-old(hero) {
  animation: fade-out 200ms ease-out;
}

::view-transition-new(hero) {
  animation: fade-in 200ms ease-in;
}
```

### Feature Detection

Always check for API support before using:

```typescript
function safeViewTransition(callback: () => void) {
  if (!document.startViewTransition) {
    callback();
    return;
  }
  document.startViewTransition(callback);
}
```

> For detailed View Transitions patterns including lightbox, page navigation with slide direction, card-to-detail transitions, and lifecycle hooks, see [references/view-transitions.md](references/view-transitions.md).

## Rules Quick Reference

| Rule | Summary |
|------|---------|
| `pseudo-content-required` | `::before`/`::after` need `content` property |
| `pseudo-over-dom-node` | Use pseudo-elements for decorative content, not extra DOM nodes |
| `pseudo-position-relative-parent` | Parent needs `position: relative` for absolute pseudo-elements |
| `pseudo-z-index-layering` | Use `z-index: -1` with `isolation: isolate` on parent |
| `pseudo-hit-target-expansion` | Negative `inset` values expand touch targets |
| `native-backdrop-styling` | Use `::backdrop` for dialog/popover backgrounds |
| `native-placeholder-styling` | Use `::placeholder` for input placeholders |
| `native-selection-styling` | Use `::selection` for text selection |
| `transition-name-required` | Elements need `view-transition-name` to participate |
| `transition-name-unique` | Names must be unique during transition |
| `transition-name-cleanup` | Remove names after transition completes |
| `transition-over-js-library` | Prefer View Transitions API for page transitions |
| `transition-style-pseudo-elements` | Style via `::view-transition-group/old/new` pseudo-elements |
