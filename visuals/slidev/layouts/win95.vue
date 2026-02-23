<!--
  win95 layout — standard content slide
  Usage: layout: win95
  Frontmatter props: windowTitle, windowIcon, statusText
-->
<script setup lang="ts">
const props = defineProps<{
  windowTitle?: string
  windowIcon?: string
  statusText?: string
}>()

const title = props.windowTitle ?? 'Container Course'
</script>

<template>
  <div class="layout-win95 w95-desktop-bg">
    <!-- Shadow behind the main window for depth -->
    <div class="window-shadow" />

    <Win95Window
      class="main-window"
      :title="title"
      :icon="windowIcon ?? '🖥'"
      :status-text="statusText ?? 'Ready'"
    >
      <div class="slide-content">
        <slot />
      </div>
    </Win95Window>
  </div>
</template>

<style scoped>
.layout-win95 {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  box-sizing: border-box;
  position: relative;
}

.window-shadow {
  position: absolute;
  top: 26px;
  left: 26px;
  right: 6px;
  bottom: 6px;
  background: rgba(0,0,0,0.35);
  pointer-events: none;
}

.main-window {
  position: relative;
  width: 100%;
  height: 100%;
  z-index: 1;
}

.slide-content {
  flex: 1;          /* fills w95-body (which is now a flex column) */
  min-height: 0;    /* allows flex children to shrink below natural size */
  color: var(--w95-black);
  font-family: var(--w95-font);
  display: flex;
  flex-direction: column;
}

/* Content typography inside the win95 layout */
.slide-content :deep(h1) {
  font-size: 1.6rem;
  font-weight: 700;
  margin: 0 0 12px;
  color: var(--w95-navy-dark);
  border-bottom: 2px solid var(--w95-navy-dark);
  padding-bottom: 6px;
}

.slide-content :deep(h2) {
  font-size: 1.2rem;
  font-weight: 700;
  margin: 0 0 10px;
  color: var(--w95-navy-dark);
}

.slide-content :deep(h3) {
  font-size: 1rem;
  font-weight: 700;
  margin: 0 0 8px;
  color: var(--w95-dark);
}

.slide-content :deep(p) {
  font-size: 0.85rem;
  line-height: 1.6;
  margin-bottom: 8px;
}

.slide-content :deep(ul),
.slide-content :deep(ol) {
  padding-left: 20px;
  font-size: 0.85rem;
  line-height: 1.7;
}

.slide-content :deep(li) {
  margin-bottom: 2px;
}

.slide-content :deep(code) {
  font-family: var(--w95-mono-font);
  font-size: 0.82em;
  background: var(--w95-white);
  box-shadow: var(--w95-inset);
  padding: 1px 5px;
  color: var(--w95-navy-dark);
}

/* ── Code blocks ──────────────────────────────────────────── */
/* .slidev-code-wrapper is the direct flex child (outer div)   */
/* .slidev-code is the <pre> element (Slidev adds this class)  */
.slide-content :deep(.slidev-code-wrapper) {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 60px;
  margin: 0 !important;
}

.slide-content :deep(.slidev-code) {
  flex: 1;
  font-family: var(--w95-mono-font) !important;
  font-size: 0.9rem !important;
  background: var(--w95-white) !important;
  box-shadow: var(--w95-inset);
  padding: 10px 14px !important;
  line-height: 1.6 !important;
  color: var(--w95-black);
  margin: 0;
  border-radius: 0 !important;
}

/* fallback for plain <pre> without Slidev wrapper */
.slide-content :deep(pre:not(.slidev-code)) {
  font-family: var(--w95-mono-font);
  font-size: 0.9rem;
  background: var(--w95-white);
  box-shadow: var(--w95-inset);
  padding: 10px 14px;
  overflow: auto;
  line-height: 1.6;
  color: var(--w95-black);
  margin-bottom: 0;
  flex: 1;
}

/* ── Win95Window components directly inside a slide (e.g. TaskManager) ── */
/* Makes them fill remaining vertical space after the heading */
.slide-content :deep(.w95-window) {
  flex: 1;
  min-height: 0;
}

.slide-content :deep(.slidev-code code),
.slide-content :deep(pre code) {
  background: none !important;
  box-shadow: none;
  padding: 0 !important;
  font-size: inherit;
}

.slide-content :deep(table) {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.84rem;
  margin-bottom: 0;
}

.slide-content :deep(th) {
  background: var(--w95-navy-dark);
  color: var(--w95-white);
  padding: 4px 10px;
  text-align: left;
  font-weight: 700;
  font-size: 0.78rem;
}

.slide-content :deep(td) {
  padding: 8px 10px;
  border-bottom: 1px solid var(--w95-light);
}

.slide-content :deep(blockquote) {
  border-left: 3px solid var(--w95-navy-dark);
  background: var(--w95-white);
  box-shadow: var(--w95-inset);
  padding: 5px 12px;
  margin: 8px 0;
  font-size: 0.85rem;
  color: var(--w95-dark);
}

.slide-content :deep(blockquote p) {
  margin-bottom: 0;
}

.slide-content :deep(tr:nth-child(even) td) {
  background: rgba(0,0,0,0.04);
}
</style>
