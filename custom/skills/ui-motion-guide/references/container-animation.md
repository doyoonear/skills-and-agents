# Container Bounds Animation & Fluid Text

Patterns for animating dimensions that CSS cannot transition natively (`auto` width/height)
and character-level text transitions.

---

## Part 1: Animating Container Bounds

### The Problem

CSS cannot transition `width: auto` or `height: auto`. When content changes size dynamically
(accordion opens, button label changes, panel expands), you need to measure the target
dimensions and animate to them explicitly.

### Core Pattern

Two-div architecture: **outer div** (animated) wraps an **inner div** (measured).

```
┌─────────────────────────── outer (motion.div) ──┐
│  animated width/height                           │
│  ┌──────────────── inner (measured div) ──────┐  │
│  │  ref={measureRef}                          │  │
│  │  natural content dimensions                │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

### useMeasure Hook

Uses `ResizeObserver` to track an element's dimensions reactively.

```tsx
import useMeasure from "react-use-measure";

function ExpandablePanel({ isOpen }: { isOpen: boolean }) {
  const [ref, bounds] = useMeasure();

  return (
    <motion.div
      animate={{ height: isOpen ? bounds.height : 0 }}
      transition={{ type: "spring", stiffness: 300, damping: 30 }}
      style={{ overflow: "hidden" }}
    >
      <div ref={ref}>
        {isOpen && <PanelContent />}
      </div>
    </motion.div>
  );
}
```

### Rules

**Guard zero bounds on mount** — `useMeasure` reports `0` initially. Animating from 0 creates
a flash-open effect on first render.

```tsx
// FAIL: Animates from 0 on mount
<motion.div animate={{ width: bounds.width }}>

// PASS: Guard against initial zero measurement
<motion.div
  animate={{ width: bounds.width || "auto" }}
  transition={bounds.width > 0
    ? { type: "spring", stiffness: 300, damping: 30 }
    : { duration: 0 }
  }
>
```

**Never measure and animate the same element** — This creates an infinite feedback loop
(resize triggers observer, observer triggers animation, animation triggers resize...).

```tsx
// FAIL: Same element measured and animated — infinite loop
const [ref, bounds] = useMeasure();
<motion.div ref={ref} animate={{ width: bounds.width }}>
  {content}
</motion.div>

// PASS: Separate measurement and animation elements
const [ref, bounds] = useMeasure();
<motion.div animate={{ width: bounds.width || "auto" }}>
  <div ref={ref}>
    {content}
  </div>
</motion.div>
```

**Use `overflow: hidden` on the animated container** — Without it, content overflows
during the transition.

```tsx
<motion.div
  animate={{ height: bounds.height }}
  style={{ overflow: "hidden" }}
>
  <div ref={ref}>{content}</div>
</motion.div>
```

---

### Common Patterns

#### Dynamic-Width Button

Button that smoothly resizes when its label changes (e.g., "Save" → "Saving..." → "Saved").

```tsx
function DynamicButton({
  children,
}: {
  children: React.ReactNode;
}) {
  const [ref, bounds] = useMeasure();

  return (
    <motion.button
      animate={{ width: bounds.width > 0 ? bounds.width : "auto" }}
      transition={{
        type: "spring",
        stiffness: 400,
        damping: 30,
      }}
      style={{ overflow: "hidden", position: "relative" }}
    >
      <div ref={ref} className="inline-flex items-center gap-2 px-4 py-2">
        {children}
      </div>
    </motion.button>
  );
}

// Usage
<DynamicButton>
  {isLoading ? (
    <>
      <Spinner /> Saving...
    </>
  ) : (
    "Save"
  )}
</DynamicButton>
```

#### Accordion

```tsx
function Accordion({
  items,
}: {
  items: { id: string; title: string; content: React.ReactNode }[];
}) {
  const [openId, setOpenId] = useState<string | null>(null);

  return (
    <div>
      {items.map((item) => (
        <AccordionItem
          key={item.id}
          item={item}
          isOpen={openId === item.id}
          onToggle={() =>
            setOpenId(openId === item.id ? null : item.id)
          }
        />
      ))}
    </div>
  );
}

function AccordionItem({
  item,
  isOpen,
  onToggle,
}: {
  item: { id: string; title: string; content: React.ReactNode };
  isOpen: boolean;
  onToggle: () => void;
}) {
  const [ref, bounds] = useMeasure();

  return (
    <div>
      <button onClick={onToggle} className="w-full text-left p-4">
        {item.title}
      </button>
      <motion.div
        animate={{
          height: isOpen ? bounds.height : 0,
          opacity: isOpen ? 1 : 0,
        }}
        transition={{
          height: {
            type: "spring",
            stiffness: 300,
            damping: 30,
          },
          opacity: { duration: 0.2 },
        }}
        style={{ overflow: "hidden" }}
      >
        <div ref={ref} className="p-4">
          {item.content}
        </div>
      </motion.div>
    </div>
  );
}
```

#### Expandable Card

```tsx
function ExpandableCard({
  preview,
  details,
}: {
  preview: React.ReactNode;
  details: React.ReactNode;
}) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [ref, bounds] = useMeasure();

  return (
    <motion.div
      layout
      className="rounded-xl border bg-white shadow-sm"
      onClick={() => setIsExpanded(!isExpanded)}
    >
      {preview}
      <motion.div
        animate={{ height: isExpanded ? bounds.height : 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        style={{ overflow: "hidden" }}
      >
        <div ref={ref}>{details}</div>
      </motion.div>
    </motion.div>
  );
}
```

---

## Part 2: Fluid Text Transitions

Smooth text transitions at the character level, inspired by the Family Crypto app.
Characters animate individually — entering, exiting, and repositioning — to create
a fluid morphing effect.

### Core Concept

1. Split old and new text into individual characters
2. Characters present in both strings animate position (layout animation)
3. New characters animate in (fade + slide)
4. Removed characters animate out (fade + slide)

### Implementation

```tsx
import { AnimatePresence, motion, LayoutGroup } from "motion/react";

function FluidText({
  value,
  className,
}: {
  value: string;
  className?: string;
}) {
  const characters = value.split("");

  return (
    <span className={className} aria-label={value}>
      <LayoutGroup>
        <AnimatePresence mode="popLayout">
          {characters.map((char, index) => (
            <motion.span
              key={`${char}-${getStableKey(value, index)}`}
              layout
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 8 }}
              transition={{
                layout: {
                  type: "spring",
                  stiffness: 400,
                  damping: 30,
                },
                opacity: { duration: 0.15 },
                y: { duration: 0.15 },
              }}
              style={{ display: "inline-block" }}
            >
              {char === " " ? "\u00A0" : char}
            </motion.span>
          ))}
        </AnimatePresence>
      </LayoutGroup>
    </span>
  );
}
```

### Stable Key Generation

The key challenge is generating stable keys so that characters shared between old and
new strings are recognized as the same element (enabling layout animation instead of
exit + enter).

```tsx
function getStableKey(text: string, index: number): string {
  const char = text[index];
  let occurrenceBefore = 0;
  for (let i = 0; i < index; i++) {
    if (text[i] === char) occurrenceBefore++;
  }
  return `${char}-${occurrenceBefore}`;
}
```

This ensures that if the text changes from "123" to "1,234", the "1", "2", "3" characters
retain their keys and animate position, while "," and "4" animate in as new characters.

### Considerations

- **Performance**: Character-level animation is expensive for long strings. Best for short
  values (prices, counters, labels) — not paragraphs.
- **Spaces**: Replace space characters with `\u00A0` (non-breaking space) so `inline-block`
  elements preserve whitespace width.
- **Accessibility**: Set `aria-label` on the container with the full text value. Individual
  character spans are presentational.
- **Reduced motion**: Collapse to a simple crossfade of the entire string.

```tsx
const prefersReduced = useReducedMotion();

if (prefersReduced) {
  return (
    <AnimatePresence mode="wait">
      <motion.span
        key={value}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.15 }}
      >
        {value}
      </motion.span>
    </AnimatePresence>
  );
}
```

### Fluid Counter Example

```tsx
function FluidCounter({ value }: { value: number }) {
  const formatted = value.toLocaleString();

  return (
    <div className="text-4xl font-mono tabular-nums">
      <FluidText value={formatted} />
    </div>
  );
}

// Usage: counter smoothly morphs between "1,234" → "1,235" → "12,345"
```
