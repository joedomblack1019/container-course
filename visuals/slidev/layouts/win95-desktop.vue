<!--
  win95-desktop layout — full desktop scene (cover/chapter slides)
  Usage: layout: win95-desktop
  Frontmatter props: week, lab
-->
<script setup lang="ts">
const props = defineProps<{
  week?: string
  lab?: string
}>()

const clock = new Date().toLocaleTimeString('en-US', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})
</script>

<template>
  <div class="layout-desktop w95-desktop-bg">

    <!-- Desktop icons — left column (SVG icons, no emoji) -->
    <div class="desktop-icons">

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- Pods: box/container shape -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2" stroke-linejoin="round">
            <rect x="2" y="10" width="28" height="18"/>
            <polyline points="2,10 16,3 30,10"/>
            <line x1="16" y1="3" x2="16" y2="10"/>
            <line x1="2" y1="16" x2="30" y2="16"/>
          </svg>
        </div>
        <div class="d-icon-label">Pods</div>
      </div>

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- Namespaces: folder -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2" stroke-linejoin="round">
            <path d="M2 10 L2 28 L30 28 L30 10 Z"/>
            <path d="M2 10 L11 4 L19 4 L19 10"/>
          </svg>
        </div>
        <div class="d-icon-label">Namespaces</div>
      </div>

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- RBAC: padlock -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2" stroke-linejoin="round">
            <rect x="6" y="14" width="20" height="16"/>
            <path d="M10 14 L10 10 A6 6 0 0 1 22 10 L22 14"/>
            <circle cx="16" cy="22" r="2.5" fill="white"/>
          </svg>
        </div>
        <div class="d-icon-label">RBAC</div>
      </div>

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- Helm: ship's wheel -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2">
            <circle cx="16" cy="16" r="5"/>
            <circle cx="16" cy="16" r="13"/>
            <line x1="16" y1="3"  x2="16" y2="11"/>
            <line x1="16" y1="21" x2="16" y2="29"/>
            <line x1="3"  y1="16" x2="11" y2="16"/>
            <line x1="21" y1="16" x2="29" y2="16"/>
            <line x1="6"  y1="6"  x2="12" y2="12"/>
            <line x1="20" y1="20" x2="26" y2="26"/>
            <line x1="26" y1="6"  x2="20" y2="12"/>
            <line x1="12" y1="20" x2="6"  y2="26"/>
          </svg>
        </div>
        <div class="d-icon-label">Helm</div>
      </div>

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- GitOps: circular arrow -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2">
            <path d="M27 16 A11 11 0 1 1 16 5"/>
            <polyline points="16,1 16,7 22,7" stroke-linejoin="round"/>
          </svg>
        </div>
        <div class="d-icon-label">GitOps</div>
      </div>

      <div class="d-icon">
        <div class="d-icon-art">
          <!-- Metrics: bar chart -->
          <svg viewBox="0 0 32 32" fill="none" stroke="white" stroke-width="2" stroke-linejoin="round">
            <rect x="3"  y="20" width="7" height="10"/>
            <rect x="12" y="13" width="7" height="17"/>
            <rect x="21" y="6"  width="7" height="24"/>
            <line x1="1" y1="30" x2="31" y2="30"/>
          </svg>
        </div>
        <div class="d-icon-label">Metrics</div>
      </div>

    </div>

    <!-- Drop shadow -->
    <div class="main-shadow" />

    <!-- Central window -->
    <div class="main-window-wrap">
      <Win95Window
        :title="`Container Course${week ? ' — Week ' + week : ''}`"
        class="main-window"
        status-text="Ready"
      >
        <div class="desktop-content">
          <!-- Badges pinned to top -->
          <div v-if="week || lab" class="badge-row">
            <span v-if="week" class="badge">Week {{ week }}</span>
            <span v-if="lab" class="badge badge-lab">{{ lab }}</span>
          </div>

          <!-- Main content centered in remaining space -->
          <div class="hero-body">
            <slot />
          </div>
        </div>
      </Win95Window>
    </div>

    <!-- Taskbar -->
    <div class="taskbar">
      <button class="start-btn">
        <!-- kubectl star logo (SVG, no emoji) -->
        <svg class="start-svg" viewBox="0 0 16 16" fill="none">
          <polygon points="8,1 10,6 15,6 11,9 13,14 8,11 3,14 5,9 1,6 6,6"
                   fill="#000080" stroke="#000080" stroke-width="0.5"/>
        </svg>
        <span class="start-text">kubectl</span>
      </button>

      <div class="taskbar-divider" />

      <div class="taskbar-window" v-if="week">
        <!-- monitor SVG -->
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.2">
          <rect x="1" y="1" width="10" height="7"/>
          <line x1="4" y1="10" x2="8" y2="10"/>
          <line x1="6" y1="8" x2="6" y2="10"/>
        </svg>
        Container Course — Week {{ week }}
      </div>

      <div class="taskbar-spacer" />

      <div class="system-tray">
        <!-- volume icon SVG -->
        <svg width="13" height="13" viewBox="0 0 13 13" fill="none" stroke="currentColor" stroke-width="1.2">
          <polygon points="3,4 7,4 7,9 3,9"/>
          <path d="M7 5 Q10 6.5 7 8"/>
          <path d="M8 3.5 Q12 6.5 8 9.5"/>
        </svg>
        <!-- network icon SVG -->
        <svg width="13" height="13" viewBox="0 0 13 13" fill="none" stroke="currentColor" stroke-width="1.2">
          <rect x="1" y="1" width="4" height="4"/>
          <rect x="8" y="1" width="4" height="4"/>
          <rect x="4.5" y="8" width="4" height="4"/>
          <line x1="3" y1="5" x2="6.5" y2="8"/>
          <line x1="10" y1="5" x2="6.5" y2="8"/>
        </svg>
        <div class="tray-clock">{{ clock }}</div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.layout-desktop {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}

/* ── Desktop icons ───────────────────────────────────────── */
.desktop-icons {
  position: absolute;
  top: 10px;
  left: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  z-index: 2;
}

.d-icon {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  width: 70px;
  cursor: pointer;
  padding: 3px;
}

.d-icon-art {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  filter: drop-shadow(1px 1px 0 rgba(0,0,0,0.5));
}

.d-icon-art svg {
  width: 34px;
  height: 34px;
}

.d-icon:hover .d-icon-art {
  opacity: 0.8;
}

.d-icon-label {
  font-family: var(--w95-font);
  font-size: 10px;
  color: var(--w95-white);
  text-align: center;
  line-height: 1.2;
  text-shadow: 1px 1px 1px var(--w95-black);
  word-break: break-word;
  max-width: 68px;
}

/* ── Main window ─────────────────────────────────────────── */
.main-shadow {
  position: absolute;
  top: 38px;
  left: 102px;
  right: 24px;
  bottom: 40px;
  background: rgba(0,0,0,0.4);
  z-index: 1;
}

.main-window-wrap {
  position: absolute;
  top: 26px;
  left: 92px;
  right: 16px;
  bottom: 32px;
  z-index: 2;
}

.main-window {
  width: 100%;
  height: 100%;
}

/* ── Content inside window ───────────────────────────────── */
.desktop-content {
  height: 100%;
  color: var(--w95-black);
  font-family: var(--w95-font);
  display: flex;
  flex-direction: column;
  justify-content: flex-start;   /* badges pin to top */
}

/* badges always at top */
.badge-row {
  display: flex;
  gap: 8px;
  margin-bottom: 0;
  padding: 8px 0 12px;
  flex-shrink: 0;
}

.badge {
  display: inline-block;
  background: var(--w95-navy-dark);
  color: var(--w95-white);
  font-family: var(--w95-font);
  font-size: 12px;
  font-weight: 700;
  padding: 3px 12px;
  letter-spacing: 0.05em;
  box-shadow: var(--w95-raised);
}

.badge-lab {
  background: #006400;
}

/* hero-body fills remaining space and centers content vertically */
.hero-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

/* ── Hero typography — BIG to fill the window ────────────── */
.desktop-content :deep(h1) {
  font-size: 3.4rem;
  font-weight: 700;
  margin: 0 0 6px;
  color: var(--w95-navy-dark);
  line-height: 1.1;
}

.desktop-content :deep(h2) {
  font-size: 1.9rem;
  font-weight: 700;
  margin: 0 0 18px;
  color: var(--w95-dark);
}

.desktop-content :deep(p) {
  font-size: 1.1rem;
  line-height: 1.6;
  color: var(--w95-dark);
  margin-bottom: 6px;
}

.desktop-content :deep(ul) {
  padding-left: 0;
  list-style: none;
  font-size: 1.15rem;
  line-height: 1.5;
  color: var(--w95-black);
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.desktop-content :deep(li) {
  background: var(--w95-white);
  box-shadow: var(--w95-raised);
  padding: 5px 12px 5px 10px;
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.desktop-content :deep(li)::before {
  content: '▶';
  font-size: 0.7em;
  color: var(--w95-navy-dark);
  flex-shrink: 0;
}

.desktop-content :deep(strong) {
  color: var(--w95-navy-dark);
}

/* ── Taskbar ─────────────────────────────────────────────── */
.taskbar {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 28px;
  background: var(--w95-silver);
  box-shadow: inset 0 1px 0 var(--w95-white), 0 -1px 0 var(--w95-gray);
  display: flex;
  align-items: center;
  padding: 0 2px;
  gap: 4px;
  z-index: 10;
}

.start-btn {
  display: flex;
  align-items: center;
  gap: 5px;
  height: 20px;
  padding: 0 8px;
  background: var(--w95-silver);
  border: none;
  cursor: pointer;
  box-shadow: var(--w95-raised);
  flex-shrink: 0;
}

.start-svg {
  width: 14px;
  height: 14px;
  flex-shrink: 0;
}

.start-text {
  font-family: var(--w95-font);
  font-weight: 700;
  font-size: 12px;
}

.start-btn:active { box-shadow: var(--w95-inset); }

.taskbar-divider {
  width: 2px;
  height: 20px;
  background: var(--w95-gray);
  box-shadow: 1px 0 0 var(--w95-white);
  flex-shrink: 0;
}

.taskbar-window {
  height: 20px;
  padding: 0 8px;
  background: var(--w95-light);
  box-shadow: var(--w95-inset);
  font-family: var(--w95-font);
  font-size: 11px;
  display: flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  max-width: 240px;
  overflow: hidden;
}

.taskbar-spacer { flex: 1; }

.system-tray {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 20px;
  padding: 0 6px;
  box-shadow: var(--w95-inset);
  background: var(--w95-silver);
}

.tray-clock {
  font-family: var(--w95-font);
  font-size: 11px;
  color: var(--w95-black);
  padding-left: 6px;
  border-left: 1px solid var(--w95-gray);
  margin-left: 2px;
  white-space: nowrap;
}
</style>
