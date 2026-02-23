<!--
  win95-terminal layout — CRT / CMD.EXE style
  Usage: layout: win95-terminal
  Frontmatter props: termTitle, termColor
-->
<script setup lang="ts">
defineProps<{
  termTitle?: string
  termColor?: 'green' | 'amber' | 'white'
}>()
</script>

<template>
  <div class="layout-terminal">
    <!-- Desktop bg visible around edges -->
    <div class="term-desktop" />

    <!-- Main terminal window -->
    <div class="term-window-wrap">
      <div class="term-shadow" />
      <div class="term-outer w95-raised">
        <!-- CMD.EXE style title bar -->
        <div class="cmd-titlebar">
          <span class="cmd-icon">▪</span>
          <span class="cmd-title">{{ termTitle ?? 'Command Prompt — kubectl' }}</span>
          <div class="cmd-controls">
            <span class="cmd-ctrl">_</span>
            <span class="cmd-ctrl">□</span>
            <span class="cmd-ctrl cmd-close">✕</span>
          </div>
        </div>

        <!-- Terminal content (slot) -->
        <div class="term-body crt">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.layout-terminal {
  width: 100%;
  height: 100%;
  background: #008080;
  background-image: radial-gradient(circle, rgba(0,0,0,0.15) 1px, transparent 1px);
  background-size: 16px 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  box-sizing: border-box;
  position: relative;
}

.term-window-wrap {
  position: relative;
  width: 100%;
  height: 100%;
  z-index: 1;
}

.term-shadow {
  position: absolute;
  top: 10px;
  left: 10px;
  right: -6px;
  bottom: -6px;
  background: rgba(0,0,0,0.5);
  z-index: 0;
}

.term-outer {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--w95-silver);
  z-index: 1;
}

/* ── CMD title bar ───────────────────────────────────────── */
.cmd-titlebar {
  display: flex;
  align-items: center;
  background: #000080;
  color: #ffffff;
  padding: 2px 4px;
  height: 20px;
  gap: 4px;
  flex-shrink: 0;
}

.cmd-icon {
  font-size: 10px;
}

.cmd-title {
  flex: 1;
  font-family: var(--w95-font);
  font-size: 12px;
  font-weight: 700;
}

.cmd-controls {
  display: flex;
  gap: 2px;
}

.cmd-ctrl {
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
  flex-shrink: 0;
}

.cmd-close {
  font-size: 8px;
}

/* ── Terminal body ───────────────────────────────────────── */
.term-body {
  flex: 1;
  background: var(--term-bg);
  padding: 8px 12px;
  overflow-y: auto;
  overflow-x: hidden;
  font-family: var(--w95-term-font);
  font-size: 18px;
  color: var(--term-green);
  line-height: 1.3;
  position: relative;
}

/* Content typography for this layout */
.term-body :deep(h1),
.term-body :deep(h2),
.term-body :deep(h3) {
  font-family: var(--w95-term-font);
  color: var(--term-green);
  text-shadow: 0 0 8px var(--term-green-dim);
  font-weight: 400;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.term-body :deep(h1) { font-size: 1.8rem; }
.term-body :deep(h2) { font-size: 1.4rem; }

.term-body :deep(p),
.term-body :deep(li) {
  font-family: var(--w95-term-font);
  font-size: 1.1rem;
  color: var(--term-green);
  text-shadow: 0 0 5px var(--term-green-dim);
  line-height: 1.4;
}

.term-body :deep(code) {
  font-family: var(--w95-mono-font);
  font-size: 0.85rem;
  color: var(--term-amber);
  background: none;
  box-shadow: none;
  padding: 0;
}

.term-body :deep(pre) {
  font-family: var(--w95-mono-font);
  font-size: 0.78rem;
  color: var(--term-green);
  background: none;
  box-shadow: none;
  padding: 4px 0;
  line-height: 1.5;
}

/* CRT scanlines overlay */
.crt::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    to bottom,
    transparent 0px, transparent 2px,
    rgba(0,0,0,0.18) 2px, rgba(0,0,0,0.18) 4px
  );
  pointer-events: none;
  z-index: 10;
}
</style>
