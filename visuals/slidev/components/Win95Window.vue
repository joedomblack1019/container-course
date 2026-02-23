<script setup lang="ts">
withDefaults(defineProps<{
  title?: string
  icon?: string
  active?: boolean
  statusText?: string
  noPadding?: boolean
  width?: string
  height?: string
  resizable?: boolean
}>(), {
  title: 'Window',
  active: true,
  noPadding: false,
})
</script>

<template>
  <div
    class="w95-window"
    :class="{ inactive: !active }"
    :style="{ width, height }"
  >
    <!-- Title bar -->
    <div class="w95-titlebar">
      <div class="w95-titlebar-left">
        <span v-if="icon" class="w95-titlebar-icon">{{ icon }}</span>
        <span class="w95-titlebar-text">{{ title }}</span>
      </div>
      <div class="w95-titlebar-controls">
        <button class="w95-ctrl-btn" title="Minimize">
          <svg width="8" height="8" viewBox="0 0 8 8">
            <rect x="0" y="6" width="8" height="2" fill="currentColor"/>
          </svg>
        </button>
        <button class="w95-ctrl-btn" title="Maximize">
          <svg width="8" height="8" viewBox="0 0 8 8">
            <rect x="0" y="0" width="8" height="8" fill="none" stroke="currentColor" stroke-width="1.5"/>
            <rect x="0" y="0" width="8" height="2" fill="currentColor"/>
          </svg>
        </button>
        <button class="w95-ctrl-btn w95-ctrl-close" title="Close">
          <svg width="8" height="8" viewBox="0 0 8 8">
            <line x1="0" y1="0" x2="8" y2="8" stroke="currentColor" stroke-width="1.5"/>
            <line x1="8" y1="0" x2="0" y2="8" stroke="currentColor" stroke-width="1.5"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- Optional menu bar slot -->
    <div v-if="$slots.menu" class="w95-menubar">
      <slot name="menu" />
    </div>

    <!-- Window body -->
    <div class="w95-body" :class="{ 'no-pad': noPadding }">
      <slot />
    </div>

    <!-- Optional status bar -->
    <div v-if="statusText || $slots.status" class="w95-statusbar">
      <div class="w95-status-cell">
        <slot name="status">{{ statusText }}</slot>
      </div>
    </div>
  </div>
</template>

<style scoped>
.w95-window {
  background: var(--w95-silver);
  box-shadow: var(--w95-raised);
  display: flex;
  flex-direction: column;
  font-family: var(--w95-font);
  min-width: 120px;
}

/* ── Title bar ───────────────────────────────────────────── */
.w95-titlebar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 2px 3px;
  height: 22px;
  flex-shrink: 0;
  background: linear-gradient(
    to right,
    var(--w95-navy-dark),
    var(--w95-navy-light)
  );
  /* subtle banding — authentic win95 detail */
  background-image:
    repeating-linear-gradient(
      to bottom,
      transparent 0px, transparent 1px,
      rgba(255,255,255,0.04) 1px, rgba(255,255,255,0.04) 2px
    ),
    linear-gradient(to right, var(--w95-navy-dark), var(--w95-navy-light));
}

.inactive .w95-titlebar {
  background: var(--w95-gray);
  background-image: none;
}

.w95-titlebar-left {
  display: flex;
  align-items: center;
  gap: 4px;
  flex: 1;
  min-width: 0;
}

.w95-titlebar-icon {
  font-size: 14px;
  line-height: 1;
  flex-shrink: 0;
}

.w95-titlebar-text {
  color: var(--w95-white);
  font-family: var(--w95-font);
  font-size: 14px;
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  letter-spacing: 0.01em;
  text-shadow: 1px 1px 0 rgba(0,0,0,0.4);
}

/* ── Control buttons ─────────────────────────────────────── */
.w95-titlebar-controls {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
  margin-left: 6px;
}

.w95-ctrl-btn {
  width: 16px;
  height: 14px;
  background: var(--w95-silver);
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--w95-raised);
  padding: 0;
  color: var(--w95-black);
  flex-shrink: 0;
}

.w95-ctrl-btn:hover {
  background: var(--w95-light);
}

.w95-ctrl-btn:active {
  box-shadow: var(--w95-inset);
  padding: 1px 0 0 1px;
}

/* ── Menu bar ────────────────────────────────────────────── */
.w95-menubar {
  display: flex;
  padding: 2px 4px;
  border-bottom: 1px solid var(--w95-gray);
  font-size: 12px;
  font-family: var(--w95-font);
  gap: 0;
  flex-shrink: 0;
}

/* ── Body ────────────────────────────────────────────────── */
.w95-body {
  flex: 1;
  min-height: 0;
  padding: 8px;
  overflow: auto;
  color: var(--w95-black);
  display: flex;
  flex-direction: column;
}

.w95-body.no-pad {
  padding: 0;
}

/* ── Status bar ──────────────────────────────────────────── */
.w95-statusbar {
  display: flex;
  border-top: 1px solid var(--w95-gray);
  padding: 2px 4px;
  gap: 4px;
  flex-shrink: 0;
}

.w95-status-cell {
  box-shadow: var(--w95-sunken);
  padding: 1px 8px;
  font-size: 12px;
  font-family: var(--w95-font);
  color: var(--w95-black);
}
</style>
