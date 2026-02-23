<script setup lang="ts">
import { computed } from 'vue'

export interface TermLine {
  text: string
  type?: 'input' | 'output' | 'error' | 'comment' | 'success'
  prompt?: string
}

const props = withDefaults(defineProps<{
  title?: string
  lines?: TermLine[]
  prompt?: string
  color?: 'green' | 'amber' | 'white'
  showCursor?: boolean
  crt?: boolean
  height?: string
}>(), {
  title: 'Command Prompt',
  lines: () => [],
  prompt: 'C:\\>',
  color: 'green',
  showCursor: true,
  crt: true,
  height: '100%',
})

const colorClass = computed(() => ({
  green: 'term-green',
  amber: 'term-amber',
  white: 'term-white',
})[props.color])
</script>

<template>
  <div class="term-shell" :class="[colorClass, { crt }]" :style="{ height }">
    <!-- Window chrome: CMD title bar -->
    <div class="term-titlebar">
      <span class="term-titlebar-icon">▪</span>
      <span class="term-titlebar-text">{{ title }}</span>
      <div class="term-controls">
        <span class="term-ctrl">_</span>
        <span class="term-ctrl">□</span>
        <span class="term-ctrl term-ctrl-x">✕</span>
      </div>
    </div>

    <!-- Terminal body -->
    <div class="term-body">
      <div
        v-for="(line, i) in lines"
        :key="i"
        class="term-line"
        :class="line.type || 'output'"
      >
        <!-- Input lines get the prompt -->
        <span v-if="line.type === 'input'" class="term-prompt">
          {{ line.prompt ?? prompt }}
        </span>
        <span class="term-text">{{ line.text }}</span>
      </div>

      <!-- Blinking cursor at end -->
      <div v-if="showCursor" class="term-line output">
        <span class="term-prompt">{{ prompt }}</span>
        <span class="cursor-blink" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.term-shell {
  display: flex;
  flex-direction: column;
  background: var(--term-bg);
  font-family: var(--w95-term-font);
  font-size: 24px;
  line-height: 1.45;
  position: relative;
  overflow: hidden;
}

/* ── Color variants ──────────────────────────────────────── */
.term-green  { --t-color: var(--term-green);  --t-glow: var(--term-green-dim); }
.term-amber  { --t-color: var(--term-amber);  --t-glow: #7a5500; }
.term-white  { --t-color: #e0e0e0;            --t-glow: transparent; }

/* ── Title bar (CMD chrome) ──────────────────────────────── */
.term-titlebar {
  display: flex;
  align-items: center;
  background: #000080;
  color: #ffffff;
  padding: 2px 6px;
  font-family: var(--w95-font);
  font-size: 12px;
  font-weight: 700;
  gap: 4px;
  flex-shrink: 0;
  height: 20px;
}

.term-titlebar-text {
  flex: 1;
  font-family: var(--w95-font);
  font-size: 12px;
}

.term-controls {
  display: flex;
  gap: 2px;
}

.term-ctrl {
  width: 14px;
  height: 12px;
  background: #c0c0c0;
  color: #000;
  font-family: var(--w95-font);
  font-size: 9px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset -1px -1px #808080, inset 1px 1px #ffffff;
  cursor: pointer;
}

.term-ctrl-x {
  font-size: 8px;
}

/* ── Body ────────────────────────────────────────────────── */
.term-body {
  flex: 1;
  padding: 8px 10px;
  overflow-y: auto;
  overflow-x: hidden;
}

/* ── Line types ──────────────────────────────────────────── */
.term-line {
  display: flex;
  gap: 0;
  margin-bottom: 3px;
  min-height: 1.45em;
  flex-wrap: wrap;
  word-break: break-all;
}

.term-prompt {
  color: var(--t-color);
  text-shadow: 0 0 5px var(--t-glow);
  margin-right: 4px;
  flex-shrink: 0;
}

.term-text {
  color: var(--t-color);
  text-shadow: 0 0 5px var(--t-glow);
}

.term-line.input .term-text {
  color: var(--t-color);
}

.term-line.output .term-text {
  color: var(--t-color);
  opacity: 0.9;
}

.term-line.error .term-text {
  color: #ff4444;
  text-shadow: 0 0 6px #aa0000;
}

.term-line.success .term-text {
  color: var(--term-green);
  text-shadow: 0 0 6px var(--term-green-dim);
}

.term-line.comment .term-text {
  color: var(--term-gray);
  opacity: 0.7;
  font-style: italic;
}

/* ── CRT scanlines (applied via ::after on .crt) ─────────── */
.crt {
  position: relative;
}

.crt::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    to bottom,
    transparent 0px,
    transparent 2px,
    rgba(0,0,0,0.15) 2px,
    rgba(0,0,0,0.15) 4px
  );
  pointer-events: none;
  z-index: 5;
}

/* ── Blinking cursor (reuse global but scoped override) ──── */
.cursor-blink {
  display: inline-block;
  width: 0.55em;
  height: 1em;
  background: var(--t-color);
  box-shadow: 0 0 6px var(--t-glow);
  animation: blink 1.1s step-end infinite;
  vertical-align: text-bottom;
}

@keyframes blink {
  0%, 49% { opacity: 1; }
  50%, 100% { opacity: 0; }
}
</style>
