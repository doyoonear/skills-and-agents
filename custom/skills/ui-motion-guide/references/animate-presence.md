# AnimatePresence — Exit Animation Patterns

Reference for Motion library's `AnimatePresence` component, which enables exit animations
for conditionally rendered elements.

## Core Concept

React unmounts elements instantly. `AnimatePresence` intercepts unmounting, runs the `exit`
animation, then removes the element from the DOM.

```tsx
import { AnimatePresence, motion } from "motion/react";

function Notification({ show }: { show: boolean }) {
  return (
    <AnimatePresence>
      {show && (
        <motion.div
          key="notification"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.2, ease: [0.4, 0, 1, 1] }}
        >
          Notification content
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

---

## Rules

### `exit-requires-wrapper`

Conditional motion elements **must** be wrapped in `AnimatePresence`.

```tsx
// FAIL: No AnimatePresence — exit prop is ignored, element vanishes instantly
{show && (
  <motion.div exit={{ opacity: 0 }}>Content</motion.div>
)}

// PASS: AnimatePresence enables the exit animation
<AnimatePresence>
  {show && (
    <motion.div
      key="content"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      Content
    </motion.div>
  )}
</AnimatePresence>
```

### `exit-prop-required`

Every direct motion child inside `AnimatePresence` needs an `exit` prop.

```tsx
// FAIL: Missing exit prop — element will just disappear
<AnimatePresence>
  {show && (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
      Content
    </motion.div>
  )}
</AnimatePresence>

// PASS
<AnimatePresence>
  {show && (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      Content
    </motion.div>
  )}
</AnimatePresence>
```

### `exit-key-required`

Dynamic lists need **unique, stable keys** (not array index).

```tsx
// FAIL: Index keys cause wrong elements to animate out
<AnimatePresence>
  {items.map((item, i) => (
    <motion.div key={i} exit={{ opacity: 0 }}>
      {item.name}
    </motion.div>
  ))}
</AnimatePresence>

// PASS: Stable unique key
<AnimatePresence>
  {items.map((item) => (
    <motion.div key={item.id} exit={{ opacity: 0 }}>
      {item.name}
    </motion.div>
  ))}
</AnimatePresence>
```

### `exit-matches-initial`

Exit should mirror initial for visual symmetry (enter from bottom → exit to bottom).

```tsx
// PASS: Symmetrical enter/exit
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: 20 }}
/>
```

---

## useIsPresent and usePresence

### `presence-hook-in-child`

`useIsPresent` must be called in a **child** component of AnimatePresence, not the parent.

```tsx
// FAIL: useIsPresent in the component that controls rendering
function Parent() {
  const isPresent = useIsPresent(); // Always true — this component never exits
  return show && <Child />;
}

// PASS: useIsPresent in the child that AnimatePresence manages
function Child() {
  const isPresent = useIsPresent();
  // isPresent becomes false during exit animation
  return <motion.div exit={{ opacity: 0 }}>...</motion.div>;
}

function Parent() {
  return (
    <AnimatePresence>
      {show && <Child key="child" />}
    </AnimatePresence>
  );
}
```

### `presence-safe-to-remove`

When using `usePresence` for manual exit control, **always call `safeToRemove`** after async work completes.

```tsx
function AsyncExitChild() {
  const [isPresent, safeToRemove] = usePresence();

  useEffect(() => {
    if (!isPresent) {
      // Run custom exit logic (e.g., canvas fade, WebGL cleanup)
      performAsyncCleanup().then(() => {
        safeToRemove(); // MUST call — otherwise element stays in DOM forever
      });
    }
  }, [isPresent, safeToRemove]);

  return <div>Custom animated content</div>;
}
```

### `presence-disable-interactions`

Disable pointer events on exiting elements to prevent ghost clicks.

```tsx
function ExitingElement() {
  const isPresent = useIsPresent();

  return (
    <motion.div
      exit={{ opacity: 0 }}
      style={{ pointerEvents: isPresent ? "auto" : "none" }}
    >
      <button onClick={handleAction}>Action</button>
    </motion.div>
  );
}
```

---

## Modes

AnimatePresence has three modes controlling how entering and exiting elements interact.

### `sync` (default)

Enter and exit happen **simultaneously**. Simple but can cause layout conflicts when
both old and new elements occupy space at the same time.

```tsx
<AnimatePresence mode="sync">
  <motion.div key={currentPage} ... />
</AnimatePresence>
```

### `wait`

Exit completes **before** enter begins. Sequential, clean, but **doubles perceived duration**.

```tsx
// CAUTION: If exit is 200ms and enter is 200ms, total transition = 400ms
<AnimatePresence mode="wait">
  <motion.div
    key={step}
    initial={{ opacity: 0 }}
    animate={{ opacity: 1 }}
    exit={{ opacity: 0 }}
    transition={{ duration: 0.15 }} // Keep short since durations stack
  />
</AnimatePresence>
```

**`mode-wait-doubles-duration`** — Halve individual durations when using "wait" mode to keep total ≤300ms.

### `popLayout`

Exiting element is **removed from document flow** immediately (via CSS `position`), while
remaining elements reflow. Best for **lists and reordering**.

```tsx
// PASS: List items reflow smoothly when one is removed
<AnimatePresence mode="popLayout">
  {items.map((item) => (
    <motion.li
      key={item.id}
      layout
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
    >
      {item.name}
    </motion.li>
  ))}
</AnimatePresence>
```

**`mode-sync-layout-conflict`** — If sync mode causes layout jumping, switch to `popLayout`.

**`mode-pop-layout-for-lists`** — Use `popLayout` for list animations where items are added/removed.

---

## Nested AnimatePresence

### `nested-propagate-required`

When a parent with `AnimatePresence` contains children that also use `AnimatePresence`,
the inner exits won't run unless `propagate` is set.

```tsx
// FAIL: Inner exit animations are skipped when parent exits
<AnimatePresence>
  {showParent && (
    <motion.div key="parent" exit={{ opacity: 0 }}>
      <AnimatePresence>
        {showChild && (
          <motion.div key="child" exit={{ scale: 0 }} />
        )}
      </AnimatePresence>
    </motion.div>
  )}
</AnimatePresence>

// PASS: propagate enables coordinated parent + child exits
<AnimatePresence>
  {showParent && (
    <motion.div key="parent" exit={{ opacity: 0 }}>
      <AnimatePresence propagate>
        {showChild && (
          <motion.div key="child" exit={{ scale: 0 }} />
        )}
      </AnimatePresence>
    </motion.div>
  )}
</AnimatePresence>
```

### `nested-consistent-timing`

Parent and child exit durations should be coordinated. Child exits should complete
before or at the same time as parent exit.

```tsx
// FAIL: Child exit (500ms) outlasts parent exit (200ms) — child gets clipped
<motion.div exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
  <motion.div exit={{ y: 50 }} transition={{ duration: 0.5 }} />
</motion.div>

// PASS: Child exit fits within parent's exit window
<motion.div exit={{ opacity: 0 }} transition={{ duration: 0.25 }}>
  <motion.div exit={{ y: 20 }} transition={{ duration: 0.15 }} />
</motion.div>
```

---

## Common Patterns

### Route Transition

```tsx
function RouteTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -8 }}
        transition={{ duration: 0.15, ease: [0, 0, 0.2, 1] }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

### Toast Notification Stack

```tsx
function ToastStack({ toasts }: { toasts: Toast[] }) {
  return (
    <div className="fixed bottom-4 right-4 flex flex-col gap-2">
      <AnimatePresence mode="popLayout">
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            layout
            initial={{ opacity: 0, x: 100, scale: 0.95 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, x: 100, scale: 0.95 }}
            transition={{
              type: "spring",
              stiffness: 400,
              damping: 30,
            }}
          >
            <ToastContent toast={toast} />
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
```

### Tab Content Swap

```tsx
function TabContent({ activeTab, content }: TabContentProps) {
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={activeTab}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.12 }}
      >
        {content}
      </motion.div>
    </AnimatePresence>
  );
}
```
