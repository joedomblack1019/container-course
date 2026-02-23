<script setup lang="ts">
withDefaults(defineProps<{
  label?: string
  emoji?: string
  selected?: boolean
  size?: 'sm' | 'md' | 'lg'
}>(), {
  label: 'Icon',
  size: 'md',
})
</script>

<template>
  <div class="w95-icon" :class="[size, { selected }]">
    <div class="w95-icon-image">
      <slot>
        <span class="w95-icon-emoji">{{ emoji }}</span>
      </slot>
    </div>
    <div class="w95-icon-label">{{ label }}</div>
  </div>
</template>

<style scoped>
.w95-icon {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  cursor: pointer;
  user-select: none;
  padding: 4px 6px;
  width: 72px;
}

.w95-icon:hover .w95-icon-image {
  opacity: 0.85;
}

/* ── Image area ──────────────────────────────────────────── */
.w95-icon-image {
  display: flex;
  align-items: center;
  justify-content: center;
  transition: opacity 0.1s;
}

.w95-icon.sm .w95-icon-image { font-size: 24px; }
.w95-icon.md .w95-icon-image { font-size: 36px; }
.w95-icon.lg .w95-icon-image { font-size: 48px; }

.w95-icon-emoji {
  line-height: 1;
  display: block;
  /* pixelated render to look more authentic */
  image-rendering: pixelated;
}

/* ── Label ───────────────────────────────────────────────── */
.w95-icon-label {
  font-family: var(--w95-font);
  font-size: 11px;
  color: var(--w95-white);
  text-align: center;
  line-height: 1.2;
  text-shadow: 1px 1px 1px var(--w95-black);
  word-break: break-word;
  max-width: 70px;
}

/* ── Selected state ──────────────────────────────────────── */
.w95-icon.selected .w95-icon-image {
  outline: 1px dotted var(--w95-white);
  filter: brightness(0.6) sepia(1) hue-rotate(200deg);
}

.w95-icon.selected .w95-icon-label {
  background: var(--w95-select-bg);
  color: var(--w95-select-text);
  text-shadow: none;
}
</style>
