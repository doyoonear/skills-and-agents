---
name: ui-sound-design
description: |
  UI sound design principles and implementation for web and mobile applications. Covers when to use sound, accessibility requirements, Web Audio API synthesis, and parameter tuning.
  This skill should be used when implementing sound feedback, adding audio cues, designing notification/confirmation/error sounds, reviewing sound accessibility, or when user mentions "UI 사운드", "소리 디자인", "오디오 피드백", "효과음", "Web Audio API".
  Not for visual animations (use ui-motion-guide) or background music/media playback.
---

# UI Sound Design

## Overview

Sound in UI is a temporal channel: the auditory cortex processes sound in ~25ms vs ~250ms for vision (10x faster). A button that clicks *feels* faster than a silent one with identical visual feedback. Sound bridges the gap between action and response, and notification chimes are present in a room without requiring visual attention.

When sight and sound conflict, humans believe their ears ("auditory dominance in temporal processing"). This makes sound powerful but also dangerous if misused.

## When to Use Sound

### Sound Appropriateness Matrix

| Interaction | Sound? | Reason |
|-------------|--------|--------|
| Payment success | **Yes** | Significant confirmation |
| Form submission | **Yes** | User needs assurance |
| Error state | **Yes** | Cannot be overlooked |
| Notification | **Yes** | User may not be looking at screen |
| Button click | **Maybe** | Only for significant/primary actions |
| Typing | **No** | Too frequent |
| Hover | **No** | Decorative only |
| Scroll | **No** | Too frequent |
| Keyboard navigation | **No** | Would create noise on every keystroke |

### Rules

**Use sound for:**
- Confirmations of major actions (payments, uploads, saves)
- Errors and warnings that cannot be overlooked
- State changes that reinforce transitions
- Notifications that interrupt without requiring visual attention

**Never use sound for:**
- High-frequency interactions (typing, keyboard navigation, scrolling)
- Decorative moments with no informational value
- Hover events
- Every button click indiscriminately

### Sound Weight Principle

Sound weight must match action importance. A delete confirmation gets a heavier sound than a toggle switch. Sound duration should match action duration: instant clicks for taps, brief tones for confirmations, slightly longer tones for errors.

## Accessibility Rules

Every rule here is non-negotiable. Sound is a complement, never a replacement.

### Rule: `a11y-visual-equivalent`

Every audio cue MUST have a visual equivalent.

```tsx
// FAIL: Sound is the only feedback
function handleSubmit() {
  playSound("success");
}

// PASS: Visual feedback accompanies sound
function handleSubmit() {
  playSound("success");
  setToast({ message: "Form submitted successfully", type: "success" });
}
```

### Rule: `a11y-toggle-setting`

Provide an explicit toggle to disable all sounds in application settings.

```tsx
// FAIL: No way to disable sounds
function playFeedback(sound: string) {
  new Audio(`/sounds/${sound}.mp3`).play();
}

// PASS: Sound respects user preference
function playFeedback(sound: string) {
  const { soundEnabled } = useSettings();
  if (!soundEnabled) return;
  new Audio(`/sounds/${sound}.mp3`).play();
}
```

### Rule: `a11y-reduced-motion-check`

Respect `prefers-reduced-motion` as a proxy for sound sensitivity.

```tsx
// FAIL: Ignores user's motion/sensory preference
function playNotification() {
  audioRef.current.play();
}

// PASS: Checks reduced-motion preference
function playNotification() {
  const prefersReduced = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;
  if (prefersReduced) return;
  audioRef.current.play();
}
```

### Rule: `a11y-volume-control`

Allow volume adjustment independent of system volume.

```tsx
// FAIL: No volume control, plays at full system volume
audio.play();

// PASS: App-level volume control
const gainNode = audioContext.createGain();
gainNode.gain.value = userVolumePreference; // 0.0 to 1.0
source.connect(gainNode);
gainNode.connect(audioContext.destination);
```

## Implementation Rules

### Rule: `impl-preload-audio`

Preload audio files to avoid delay on first play.

```tsx
// FAIL: Loads audio on demand, causing delay
function handleClick() {
  const audio = new Audio("/sounds/click.mp3");
  audio.play();
}

// PASS: Preloaded audio ready for instant playback
const clickSound = new Audio("/sounds/click.mp3");
clickSound.preload = "auto";

function handleClick() {
  clickSound.currentTime = 0;
  clickSound.play();
}
```

### Rule: `impl-default-subtle`

Default volume must be subtle. Never start at full volume.

```tsx
// FAIL: Full volume by default
const audio = new Audio("/sounds/notification.mp3");
audio.play(); // volume defaults to 1.0

// PASS: Subtle default volume
const audio = new Audio("/sounds/notification.mp3");
audio.volume = 0.3;
audio.play();
```

### Rule: `impl-reset-current-time`

Reset `currentTime` before replaying a sound. Without this, rapid successive plays may not fire.

```tsx
// FAIL: Rapid clicks may not produce sound
function handleClick() {
  clickSound.play();
}

// PASS: Reset ensures each play starts from beginning
function handleClick() {
  clickSound.currentTime = 0;
  clickSound.play();
}
```

### Rule: `appropriate-no-punishing`

Sound informs, it does not punish. Error sounds should be gentle alerts, not loud buzzers.

```tsx
// FAIL: Aggressive error sound
function playError() {
  const audio = new Audio("/sounds/loud-buzzer.mp3");
  audio.volume = 1.0;
  audio.play();
}

// PASS: Gentle, informative error sound
function playError() {
  const audio = new Audio("/sounds/gentle-alert.mp3");
  audio.volume = 0.3;
  audio.play();
}
```

## Web Audio API Synthesis

For programmatic sound generation (no audio files needed), see the detailed reference:

**Reference:** `references/web-audio-synthesis.md`

Covers:
- AudioContext management (single instance, suspended state, node cleanup)
- Noise generation and filtering for percussive sounds (clicks, taps)
- Oscillators with pitch sweeps for tonal sounds (confirmations, errors)
- Envelope shaping with exponential decay
- Complete recipes for click, success, error, and notification sounds
- Node graph patterns and signal flow

### Key Synthesis Rules (Summary)

| Rule ID | Rule |
|---------|------|
| `context-reuse-single` | Reuse a single AudioContext instance |
| `context-resume-suspended` | Check and resume suspended context before playing |
| `context-cleanup-nodes` | Disconnect nodes after playback via `onended` |
| `envelope-exponential-decay` | Use exponential ramps, not linear, for natural decay |
| `envelope-no-zero-target` | Cannot target 0 with exponential ramp; use 0.001 |
| `envelope-set-initial-value` | Call `setValueAtTime` before any ramp |
| `design-noise-for-percussion` | Use filtered noise for clicks and taps |
| `design-oscillator-for-tonal` | Use oscillators with pitch sweep for tonal sounds |
| `design-filter-for-character` | Use bandpass filter to shape percussive character |

### Key Parameter Ranges

| Parameter | Range |
|-----------|-------|
| Click duration | 5-15ms |
| Bandpass frequency (clicks) | 3000-6000Hz |
| Filter Q | 2-5 |
| Gain | 0.1-0.5, never exceed 1.0 |

## Parameter Translation Table

When a user describes an issue with sound output, map their description to parameter adjustments:

| User Says | Parameter Change |
|-----------|------------------|
| "too harsh" | Lower filter frequency, reduce Q |
| "too muffled" | Higher filter frequency |
| "too long" | Shorter duration, faster decay |
| "cuts off abruptly" | Switch to exponential decay |
| "more mechanical" | Higher Q, faster decay |
| "softer" | Lower gain, use triangle wave |
| "too quiet" | Increase gain (keep <= 1.0) |
| "too ringy" | Lower Q value |
| "too dull" | Higher filter frequency, higher Q |

## Common Counter-Arguments

| Objection | Response |
|-----------|----------|
| "Users will hate it" | Only if done poorly. Subtle + appropriate + optional = accepted. |
| "It's inaccessible" | Sound complements, never replaces. Visual equivalent always required. |
| "It's technically complicated" | Basic Audio objects or Web Audio API cover most cases. |
| "It's not professional" | Cultural inertia. Native apps use sound constantly. |

## Output Format

When reviewing or implementing sound in a codebase, report findings in this format:

```
file:line  [RULE_ID]  description of issue or recommendation
```

Example:
```
src/components/PaymentForm.tsx:45  [a11y-visual-equivalent]  playSound("success") has no visual feedback
src/hooks/useSound.ts:12          [impl-default-subtle]      volume defaults to 1.0, should be ~0.3
src/utils/audio.ts:8              [context-reuse-single]      new AudioContext() called per sound, should reuse
```

### Summary Table

After listing findings, provide a summary:

| Category | Pass | Fail | Rules Checked |
|----------|------|------|---------------|
| Accessibility | 2 | 1 | a11y-visual-equivalent, a11y-toggle-setting, a11y-reduced-motion-check |
| Implementation | 3 | 0 | impl-preload-audio, impl-default-subtle, impl-reset-current-time |
| Appropriateness | 1 | 1 | appropriate-no-high-frequency, appropriate-no-punishing |

## All Rule IDs

| ID | Summary |
|----|---------|
| `a11y-visual-equivalent` | Every audio cue has a visual equivalent |
| `a11y-toggle-setting` | Explicit toggle to disable sounds |
| `a11y-reduced-motion-check` | Respect prefers-reduced-motion |
| `a11y-volume-control` | Volume adjustment independent of system |
| `appropriate-no-high-frequency` | No sound on typing, keyboard nav, scroll |
| `appropriate-confirmations-only` | Sound for significant actions only |
| `appropriate-errors-warnings` | Sound for errors and warnings |
| `appropriate-no-decorative` | No sound for decorative moments |
| `appropriate-no-punishing` | Sound informs, not punishes |
| `impl-preload-audio` | Preload audio files |
| `impl-default-subtle` | Default volume ~0.3, not 1.0 |
| `impl-reset-current-time` | Reset currentTime before replay |
| `weight-match-action` | Sound weight matches action importance |
| `weight-duration-matches-action` | Sound duration matches action duration |
| `context-reuse-single` | Reuse single AudioContext |
| `context-resume-suspended` | Resume suspended context before play |
| `context-cleanup-nodes` | Disconnect nodes after playback |
| `envelope-exponential-decay` | Exponential ramps, not linear |
| `envelope-no-zero-target` | Target 0.001, not 0, for exponential |
| `envelope-set-initial-value` | Set initial value before ramping |
| `design-noise-for-percussion` | Filtered noise for clicks/taps |
| `design-oscillator-for-tonal` | Oscillators with pitch sweep for tonal |
| `design-filter-for-character` | Bandpass filter shapes percussive sounds |
| `param-click-duration` | Click sounds 5-15ms |
| `param-filter-frequency-range` | Bandpass for clicks 3000-6000Hz |
| `param-reasonable-gain` | Gain <= 1.0 |
| `param-q-value-range` | Filter Q 2-5 |
