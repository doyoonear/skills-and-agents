# View Transitions API Reference

## Overview

The View Transitions API provides a mechanism for creating animated transitions between DOM states. It captures the before/after state and generates a pseudo-element tree for animating the change.

## Core Mechanism

### How `document.startViewTransition()` Works

```
1. Capture old state (snapshot)
2. Apply DOM changes (callback)
3. Capture new state (snapshot)
4. Generate pseudo-element tree
5. Animate from old → new
```

### Basic Usage

```typescript
document.startViewTransition(() => {
  // Apply DOM changes here
  updateDOM();
});
```

### Async Callback Pattern

```typescript
document.startViewTransition(async () => {
  const data = await fetchNewContent();
  container.innerHTML = renderContent(data);
});
```

## Pseudo-Element Tree

The API generates this pseudo-element structure during transition:

```
::view-transition
├── ::view-transition-group(name)
│   └── ::view-transition-image-pair(name)
│       ├── ::view-transition-old(name)
│       └── ::view-transition-new(name)
```

### Styling Transition Pseudo-Elements

```css
/* Style the transition group (controls position/size animation) */
::view-transition-group(hero-image) {
  animation-duration: 300ms;
  animation-timing-function: ease-in-out;
}

/* Style the old snapshot (fading out) */
::view-transition-old(hero-image) {
  animation: fade-out 200ms ease-out;
}

/* Style the new snapshot (fading in) */
::view-transition-new(hero-image) {
  animation: fade-in 200ms ease-in;
}
```

## `view-transition-name` Property

### Rules

1. **Required**: Elements must have `view-transition-name` to participate in transitions
2. **Unique**: Names must be unique on the page during a transition
3. **Cleanup**: Remove names from source after transition starts, add to target

### Fail: Duplicate Names During Transition

```css
/* Both visible at same time = name collision error */
.card-1 {
  view-transition-name: card;
}
.card-2 {
  view-transition-name: card;
}
```

### Pass: Unique Names Per Element

```css
.card-1 {
  view-transition-name: card-1;
}
.card-2 {
  view-transition-name: card-2;
}
```

### Dynamic Name Assignment (React/JS)

```tsx
function ImageGrid({ images, onSelect }: ImageGridProps) {
  return (
    <div className="grid">
      {images.map((img) => (
        <img
          key={img.id}
          src={img.src}
          style={{ viewTransitionName: `image-${img.id}` }}
          onClick={() => onSelect(img)}
        />
      ))}
    </div>
  );
}
```

## Shared Element Transitions

### Image Lightbox Pattern

A common use case: clicking a thumbnail expands it into a full-screen view.

```tsx
function Gallery() {
  const [selected, setSelected] = useState<Image | null>(null);

  const handleSelect = (image: Image) => {
    document.startViewTransition(() => {
      setSelected(image);
    });
  };

  const handleClose = () => {
    document.startViewTransition(() => {
      setSelected(null);
    });
  };

  return (
    <>
      <div className="grid">
        {images.map((img) => (
          <img
            key={img.id}
            src={img.src}
            style={{
              viewTransitionName: selected ? undefined : `photo-${img.id}`,
            }}
            onClick={() => handleSelect(img)}
          />
        ))}
      </div>

      {selected && (
        <div className="lightbox" onClick={handleClose}>
          <img
            src={selected.src}
            style={{ viewTransitionName: `photo-${selected.id}` }}
          />
        </div>
      )}
    </>
  );
}
```

Key points:
- The thumbnail removes its `viewTransitionName` when lightbox opens (avoids duplicate)
- The lightbox image takes the same name to create shared element transition
- On close, the reverse happens

### Name Cleanup Strategy

```tsx
const handleTransition = (sourceEl: HTMLElement, targetEl: HTMLElement) => {
  const name = sourceEl.style.viewTransitionName;

  document.startViewTransition(() => {
    sourceEl.style.viewTransitionName = '';
    targetEl.style.viewTransitionName = name;
  });
};
```

## Page Navigation Transitions

### SPA Route Transitions

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

  return <Routes>{/* ... */}</Routes>;
}
```

### Slide Direction Based on Navigation

```css
/* Default: slide left (forward navigation) */
::view-transition-old(page) {
  animation: slide-out-left 300ms ease-in-out;
}
::view-transition-new(page) {
  animation: slide-in-right 300ms ease-in-out;
}

/* Back navigation: slide right */
.navigating-back::view-transition-old(page) {
  animation: slide-out-right 300ms ease-in-out;
}
.navigating-back::view-transition-new(page) {
  animation: slide-in-left 300ms ease-in-out;
}

@keyframes slide-out-left {
  to { transform: translateX(-100%); }
}
@keyframes slide-in-right {
  from { transform: translateX(100%); }
}
@keyframes slide-out-right {
  to { transform: translateX(100%); }
}
@keyframes slide-in-left {
  from { transform: translateX(-100%); }
}
```

### Setting Direction Class in JS

```tsx
const navigateWithTransition = (path: string, direction: 'forward' | 'back') => {
  if (!document.startViewTransition) {
    navigate(path);
    return;
  }

  if (direction === 'back') {
    document.documentElement.classList.add('navigating-back');
  }

  const transition = document.startViewTransition(() => {
    navigate(path);
  });

  transition.finished.then(() => {
    document.documentElement.classList.remove('navigating-back');
  });
};
```

## Card-to-Detail Transition

A common mobile pattern: tapping a card expands into a detail page.

### List Page

```tsx
function ProductList({ products }: ProductListProps) {
  return (
    <div style={{ viewTransitionName: 'page' }}>
      {products.map((product) => (
        <div
          key={product.id}
          style={{ viewTransitionName: `product-${product.id}` }}
          onClick={() => navigateWithTransition(`/product/${product.id}`, 'forward')}
        >
          <img src={product.image} />
          <h3>{product.name}</h3>
        </div>
      ))}
    </div>
  );
}
```

### Detail Page

```tsx
function ProductDetail({ product }: ProductDetailProps) {
  return (
    <div style={{ viewTransitionName: 'page' }}>
      <div style={{ viewTransitionName: `product-${product.id}` }}>
        <img src={product.image} />
        <h1>{product.name}</h1>
        <p>{product.description}</p>
      </div>
    </div>
  );
}
```

### Transition Styles

```css
::view-transition-group(page) {
  animation-duration: 300ms;
}

/* Product card → detail morph */
::view-transition-group(product-*) {
  animation-duration: 250ms;
  animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}
```

## Transition Lifecycle Hooks

```typescript
const transition = document.startViewTransition(() => {
  updateDOM();
});

// When old state is captured
transition.ready.then(() => {
  console.log('Pseudo-element tree created, animation starting');
});

// When transition animation finishes
transition.finished.then(() => {
  console.log('Transition complete, cleanup here');
});

// Skip default animation and use custom
transition.ready.then(() => {
  document.documentElement.animate(
    [
      { clipPath: 'circle(0% at 50% 50%)' },
      { clipPath: 'circle(100% at 50% 50%)' },
    ],
    {
      duration: 500,
      easing: 'ease-in-out',
      pseudoElement: '::view-transition-new(root)',
    }
  );
});
```

## Feature Detection & Fallback

```typescript
function safeStartViewTransition(callback: () => void) {
  if (!document.startViewTransition) {
    callback();
    return;
  }
  document.startViewTransition(callback);
}
```

## Cross-Document View Transitions (MPA)

For multi-page applications (requires same-origin navigation):

```css
@view-transition {
  navigation: auto;
}
```

Elements on both pages with matching `view-transition-name` values will animate between pages automatically.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Duplicate `view-transition-name` | Ensure uniqueness, remove from source when adding to target |
| No fallback for unsupported browsers | Always check `document.startViewTransition` existence |
| Transition on heavy DOM updates | Keep DOM changes minimal inside the callback |
| Missing `view-transition-name` on target | Both source and target elements need the name |
| Name not cleaned up after transition | Use `transition.finished` to remove temporary names |
