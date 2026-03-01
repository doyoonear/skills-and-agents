# Morphing Icons

SVG line-based icon morphing system where every icon is built from exactly 3 animated lines.

## Core Concept

All icons share the same 14x14 SVG viewBox and consist of exactly **3 `<line>` elements**.
Icons that visually need fewer lines collapse the unused ones to center points with `opacity: 0`.
Transitions between icons animate line endpoints, creating smooth morphing effects.

---

## Rules

### `morphing-three-lines`

Every icon definition must have exactly 3 lines.

```tsx
// FAIL: Icon with 2 lines — breaks morph transitions
const menuIcon = {
  lines: [
    { x1: 2, y1: 4, x2: 12, y2: 4 },
    { x1: 2, y1: 10, x2: 12, y2: 10 },
  ],
};

// PASS: 3 lines — unused lines collapse to center
const menuIcon = {
  lines: [
    { x1: 2, y1: 4, x2: 12, y2: 4 },
    { x1: 2, y1: 7, x2: 12, y2: 7 },
    { x1: 2, y1: 10, x2: 12, y2: 10 },
  ],
};
```

### `morphing-use-collapsed`

Unused lines use a collapsed constant (center point, zero opacity).

```tsx
const COLLAPSED = { x1: 7, y1: 7, x2: 7, y2: 7, opacity: 0 };

// Check icon: only needs 2 visible lines, third collapses
const checkIcon = {
  lines: [
    { x1: 2, y1: 7, x2: 6, y2: 11 },     // short leg
    { x1: 6, y1: 11, x2: 12, y2: 3 },     // long leg
    { ...COLLAPSED },                       // third line hidden
  ],
};
```

### `morphing-consistent-viewbox`

All icons share the same viewBox.

```tsx
// PASS: Consistent viewBox across all morphing icons
<svg viewBox="0 0 14 14" width={size} height={size}>
  {lines.map((line, i) => (
    <motion.line key={i} {...line} />
  ))}
</svg>
```

### `morphing-group-variants`

Icons that share a rotation group animate rotation between each other.
Group is defined by a shared `group` identifier and `base` line definitions.

```tsx
type IconDefinition = {
  lines: LineCoords[];
  group?: string;       // rotation group identifier
  rotation?: number;    // rotation within group (degrees)
};

// Menu and X share a group — they morph via rotation
const menuIcon: IconDefinition = {
  lines: [
    { x1: 2, y1: 4, x2: 12, y2: 4 },
    { x1: 2, y1: 7, x2: 12, y2: 7 },
    { x1: 2, y1: 10, x2: 12, y2: 10 },
  ],
  group: "menu",
  rotation: 0,
};

const closeIcon: IconDefinition = {
  lines: [
    { x1: 3, y1: 3, x2: 11, y2: 11 },
    { ...COLLAPSED },
    { x1: 11, y1: 3, x2: 3, y2: 11 },
  ],
  group: "menu",
  rotation: 90,
};
```

### `morphing-spring-rotation`

Use spring physics for rotation transitions within a group.

```tsx
// PASS: Spring rotation for grouped icon transitions
<motion.svg
  animate={{ rotate: currentIcon.rotation ?? 0 }}
  transition={{
    type: "spring",
    stiffness: 200,
    damping: 20,
  }}
  viewBox="0 0 14 14"
>
  {currentIcon.lines.map((line, i) => (
    <motion.line
      key={i}
      animate={{
        x1: line.x1,
        y1: line.y1,
        x2: line.x2,
        y2: line.y2,
        opacity: line.opacity ?? 1,
      }}
      transition={{
        type: "spring",
        stiffness: 300,
        damping: 25,
      }}
    />
  ))}
</motion.svg>
```

### `morphing-jump-non-grouped`

When transitioning between icons that do NOT share a group, reset rotation instantly
(no animated rotation).

```tsx
function MorphIcon({ icon }: { icon: IconDefinition }) {
  const prevGroupRef = useRef(icon.group);

  const isSameGroup = prevGroupRef.current === icon.group;

  useEffect(() => {
    prevGroupRef.current = icon.group;
  }, [icon.group]);

  return (
    <motion.svg
      animate={{ rotate: icon.rotation ?? 0 }}
      transition={
        isSameGroup
          ? { type: "spring", stiffness: 200, damping: 20 }
          : { duration: 0 } // Instant jump for non-grouped
      }
      viewBox="0 0 14 14"
    >
      {/* lines */}
    </motion.svg>
  );
}
```

### `morphing-reduced-motion`

Respect `prefers-reduced-motion` — skip morphing, show target icon instantly.

```tsx
const prefersReduced = useReducedMotion();

<motion.line
  animate={{ x1, y1, x2, y2, opacity }}
  transition={
    prefersReduced
      ? { duration: 0 }
      : { type: "spring", stiffness: 300, damping: 25 }
  }
/>
```

### `morphing-strokelinecap-round`

All lines use round line caps for consistent visual style.

```tsx
<motion.line
  strokeLinecap="round"
  stroke="currentColor"
  strokeWidth={1.5}
/>
```

### `morphing-aria-hidden`

Morphing icons are decorative — always set `aria-hidden="true"`.

```tsx
<svg aria-hidden="true" viewBox="0 0 14 14">
  {/* lines */}
</svg>
```

---

## Complete Implementation Example

```tsx
import { motion, useReducedMotion } from "motion/react";
import { useRef, useEffect } from "react";

type LineCoords = {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  opacity?: number;
};

type IconDef = {
  lines: [LineCoords, LineCoords, LineCoords];
  group?: string;
  rotation?: number;
};

const COLLAPSED: LineCoords = { x1: 7, y1: 7, x2: 7, y2: 7, opacity: 0 };

const ICONS = {
  menu: {
    lines: [
      { x1: 2, y1: 4, x2: 12, y2: 4 },
      { x1: 2, y1: 7, x2: 12, y2: 7 },
      { x1: 2, y1: 10, x2: 12, y2: 10 },
    ],
    group: "nav",
    rotation: 0,
  },
  close: {
    lines: [
      { x1: 3, y1: 3, x2: 11, y2: 11 },
      { ...COLLAPSED },
      { x1: 11, y1: 3, x2: 3, y2: 11 },
    ],
    group: "nav",
    rotation: 90,
  },
  check: {
    lines: [
      { x1: 2, y1: 7, x2: 6, y2: 11 },
      { x1: 6, y1: 11, x2: 12, y2: 3 },
      { ...COLLAPSED },
    ],
  },
} satisfies Record<string, IconDef>;

function MorphIcon({
  icon,
  size = 24,
}: {
  icon: keyof typeof ICONS;
  size?: number;
}) {
  const def = ICONS[icon];
  const prefersReduced = useReducedMotion();
  const prevGroupRef = useRef(def.group);
  const isSameGroup = prevGroupRef.current === def.group;

  useEffect(() => {
    prevGroupRef.current = def.group;
  }, [def.group]);

  const lineTransition = prefersReduced
    ? { duration: 0 }
    : { type: "spring" as const, stiffness: 300, damping: 25 };

  const rotateTransition = prefersReduced || !isSameGroup
    ? { duration: 0 }
    : { type: "spring" as const, stiffness: 200, damping: 20 };

  return (
    <motion.svg
      aria-hidden="true"
      viewBox="0 0 14 14"
      width={size}
      height={size}
      animate={{ rotate: def.rotation ?? 0 }}
      transition={rotateTransition}
    >
      {def.lines.map((line, i) => (
        <motion.line
          key={i}
          strokeLinecap="round"
          stroke="currentColor"
          strokeWidth={1.5}
          animate={{
            x1: line.x1,
            y1: line.y1,
            x2: line.x2,
            y2: line.y2,
            opacity: line.opacity ?? 1,
          }}
          transition={lineTransition}
        />
      ))}
    </motion.svg>
  );
}

export { MorphIcon, ICONS, COLLAPSED };
export type { IconDef, LineCoords };
```

---

## Adding New Icons

1. Define 3 lines within the 14x14 viewBox
2. Use `COLLAPSED` for any line not needed
3. Assign a `group` and `rotation` if the icon should morph via rotation with related icons
4. Icons without a group will morph via line endpoint interpolation only (instant rotation jump)
