# Web Audio API Synthesis Patterns

Programmatic sound generation using the Web Audio API. Use this reference when implementing UI sounds without audio files.

## AudioContext Management

### Single Instance Pattern

Create one AudioContext and reuse it across the application. Multiple contexts waste resources and can cause browser limits.

```typescript
let audioContext: AudioContext | null = null;

function getAudioContext(): AudioContext {
  if (!audioContext) {
    audioContext = new AudioContext();
  }
  return audioContext;
}
```

### Suspended Context Handling

Browsers suspend AudioContext until user interaction. Always check and resume before playing.

```typescript
async function ensureContextReady(): Promise<AudioContext> {
  const ctx = getAudioContext();
  if (ctx.state === "suspended") {
    await ctx.resume();
  }
  return ctx;
}
```

Resume on first user gesture (click, keydown, touchstart). After the first resume, subsequent plays work without interaction.

### Node Cleanup

Disconnect and dereference audio nodes after playback. Nodes that remain connected leak memory.

```typescript
function playWithCleanup(ctx: AudioContext, duration: number) {
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  osc.connect(gain);
  gain.connect(ctx.destination);

  osc.start();
  osc.stop(ctx.currentTime + duration);

  osc.onended = () => {
    osc.disconnect();
    gain.disconnect();
  };
}
```

## Core Sound Design Concepts

### Noise Generation

Random sample values produce white noise. Raw noise is harsh; filtering makes it useful for percussive sounds (clicks, taps, snaps).

```typescript
function createNoiseBuffer(ctx: AudioContext, duration: number): AudioBuffer {
  const sampleRate = ctx.sampleRate;
  const length = Math.ceil(sampleRate * duration);
  const buffer = ctx.createBuffer(1, length, sampleRate);
  const data = buffer.getChannelData(0);

  for (let i = 0; i < length; i++) {
    data[i] = Math.random() * 2 - 1;
  }

  return buffer;
}
```

### Filter Types and Their Character

| Filter Type | Effect | Use Case |
|-------------|--------|----------|
| **lowpass** | Removes highs, muffled sound | Soft thuds, muted feedback |
| **highpass** | Removes lows, thin/harsh | Sharp alerts, bright ticks |
| **bandpass** | Keeps specific range | Clicks, taps, keyboard sounds |

Bandpass in the 3000-6000Hz range produces clean click sounds. Lower frequencies produce duller clicks, higher frequencies produce sharper ones.

### Filter Parameters

- **frequency**: Center frequency in Hz. Determines the "brightness" of the sound.
- **Q (quality factor)**: Narrowness of the band. Higher Q = more resonant, more "ringy". Range 2-5 for UI sounds.

```typescript
function createFilteredClick(ctx: AudioContext): void {
  const buffer = createNoiseBuffer(ctx, 0.01);
  const source = ctx.createBufferSource();
  source.buffer = buffer;

  const filter = ctx.createBiquadFilter();
  filter.type = "bandpass";
  filter.frequency.value = 4000;
  filter.Q.value = 3;

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.3, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.01);

  source.connect(filter);
  filter.connect(gain);
  gain.connect(ctx.destination);

  source.start();
  source.onended = () => {
    source.disconnect();
    filter.disconnect();
    gain.disconnect();
  };
}
```

### Envelopes (Volume Over Time)

Envelopes control how a sound's volume changes. The two critical phases for UI sounds:

- **Attack**: How quickly the sound reaches full volume (instant for clicks)
- **Decay**: How quickly the sound fades out

Always use exponential ramps for decay. Linear ramps sound unnatural.

```typescript
// WRONG: Linear decay sounds robotic
gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.015);

// RIGHT: Exponential decay sounds natural
// Note: exponentialRampToValueAtTime cannot target 0, use 0.001
gain.gain.setValueAtTime(0.3, ctx.currentTime);
gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.015);
```

The `setValueAtTime` call before the ramp is required. Without it, the ramp has no starting point and may not work correctly.

### Oscillators for Tonal Sounds

Oscillators produce pitched tones. Adding pitch movement (frequency sweep) creates more interesting sounds than static tones.

```typescript
function createConfirmationTone(ctx: AudioContext): void {
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.setValueAtTime(400, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(600, ctx.currentTime + 0.1);

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);

  osc.connect(gain);
  gain.connect(ctx.destination);

  osc.start();
  osc.stop(ctx.currentTime + 0.15);

  osc.onended = () => {
    osc.disconnect();
    gain.disconnect();
  };
}
```

| Oscillator Type | Character | Use Case |
|-----------------|-----------|----------|
| **sine** | Pure, clean | Subtle confirmations, gentle notifications |
| **triangle** | Soft, warm | Softer variations of sine |
| **square** | Harsh, buzzy | Retro/game-like sounds (rarely for UI) |
| **sawtooth** | Bright, aggressive | Almost never for UI sounds |

## Sound Recipes

### Click (Button Press)

Filtered noise, 5-15ms duration, bandpass 3000-6000Hz.

```typescript
function playClick(ctx: AudioContext): void {
  const duration = 0.01;
  const buffer = createNoiseBuffer(ctx, duration);
  const source = ctx.createBufferSource();
  source.buffer = buffer;

  const filter = ctx.createBiquadFilter();
  filter.type = "bandpass";
  filter.frequency.value = 4000;
  filter.Q.value = 3;

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.3, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);

  source.connect(filter);
  filter.connect(gain);
  gain.connect(ctx.destination);

  source.start();
  source.onended = () => {
    source.disconnect();
    filter.disconnect();
    gain.disconnect();
  };
}
```

### Success / Confirmation

Rising pitch sweep (low to high), sine oscillator, ~100-150ms.

```typescript
function playSuccess(ctx: AudioContext): void {
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.setValueAtTime(400, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(800, ctx.currentTime + 0.12);

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);

  osc.connect(gain);
  gain.connect(ctx.destination);

  osc.start();
  osc.stop(ctx.currentTime + 0.15);

  osc.onended = () => {
    osc.disconnect();
    gain.disconnect();
  };
}
```

### Error / Warning

Falling pitch sweep (high to low) or two-tone descending, ~150-200ms.

```typescript
function playError(ctx: AudioContext): void {
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.setValueAtTime(500, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(300, ctx.currentTime + 0.15);

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.25, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.2);

  osc.connect(gain);
  gain.connect(ctx.destination);

  osc.start();
  osc.stop(ctx.currentTime + 0.2);

  osc.onended = () => {
    osc.disconnect();
    gain.disconnect();
  };
}
```

### Notification

Short sine ping, moderate pitch, ~80-120ms.

```typescript
function playNotification(ctx: AudioContext): void {
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.setValueAtTime(600, ctx.currentTime);

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0.15, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);

  osc.connect(gain);
  gain.connect(ctx.destination);

  osc.start();
  osc.stop(ctx.currentTime + 0.1);

  osc.onended = () => {
    osc.disconnect();
    gain.disconnect();
  };
}
```

## Parameter Tuning Reference

### Parameter Translation Table

When a user describes a problem with a sound, adjust these parameters:

| User Says | Parameter Change |
|-----------|------------------|
| "too harsh" | Lower filter frequency, reduce Q |
| "too muffled" | Higher filter frequency |
| "too long" | Shorter duration, faster decay |
| "cuts off abruptly" | Use exponential decay (not linear) |
| "more mechanical" | Higher Q, faster decay |
| "softer" | Lower gain, use triangle wave instead of sine |
| "too quiet" | Increase gain (but keep <= 1.0) |
| "too ringy" | Lower Q value |
| "too dull" | Higher filter frequency, higher Q |

### Safe Parameter Ranges for UI Sounds

| Parameter | Range | Notes |
|-----------|-------|-------|
| Click duration | 5-15ms | Longer = more "thuddy" |
| Confirmation duration | 100-200ms | Keep brief |
| Error duration | 150-300ms | Slightly longer than success |
| Notification duration | 80-150ms | Quick ping |
| Bandpass frequency | 3000-6000Hz | For click/tap sounds |
| Filter Q | 2-5 | Higher = more resonant |
| Gain | 0.1-0.5 | Default around 0.3 |
| Max gain | 1.0 | Never exceed |

### Node Graph Patterns

Standard signal flow for UI sounds:

```
Source (Oscillator/BufferSource)
  → Filter (optional, for noise-based sounds)
    → GainNode (envelope + volume control)
      → destination
```

For layered sounds (e.g., click + tonal confirmation):

```
NoiseSource → BandpassFilter → GainNode ─┐
                                          ├→ MasterGain → destination
OscillatorSource → GainNode ─────────────┘
```

Use a master GainNode to control overall volume. This maps to the user's volume preference setting.

```typescript
function createMasterGain(ctx: AudioContext, volume: number): GainNode {
  const master = ctx.createGain();
  master.gain.value = volume;
  master.connect(ctx.destination);
  return master;
}
```
