<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  value?: number
  max?: number
  label?: string
  sublabel?: string
  color?: string
  animated?: boolean
  showPercent?: boolean
}>(), {
  value: 0,
  max: 100,
  color: '#000080',
  animated: false,
  showPercent: true,
})

const pct = computed(() => Math.min(100, Math.max(0, (props.value / props.max) * 100)))
const pctLabel = computed(() => `${Math.round(pct.value)}%`)
</script>

<template>
  <div class="w95-progress-wrap">
    <!-- Labels above bar -->
    <div v-if="label || showPercent" class="w95-progress-header">
      <span class="w95-progress-label">{{ label }}</span>
      <span v-if="showPercent" class="w95-progress-pct">{{ pctLabel }}</span>
    </div>

    <!-- The bar itself (inset well) -->
    <div class="w95-progress-track">
      <div
        class="w95-progress-fill"
        :class="{ animated }"
        :style="{ width: pct + '%', background: color }"
      />
    </div>

    <div v-if="sublabel" class="w95-progress-sublabel">{{ sublabel }}</div>
  </div>
</template>

<style scoped>
.w95-progress-wrap {
  font-family: var(--w95-font);
}

.w95-progress-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 4px;
  font-size: 12px;
  color: var(--w95-black);
}

.w95-progress-label {
  font-weight: 500;
}

.w95-progress-pct {
  color: var(--w95-dark);
  font-size: 11px;
}

/* Inset track */
.w95-progress-track {
  height: 18px;
  background: var(--w95-white);
  box-shadow: var(--w95-inset);
  position: relative;
  overflow: hidden;
}

/* Win95's chunky block-fill style */
.w95-progress-fill {
  height: 100%;
  transition: width 0.4s ease;
  background-image: repeating-linear-gradient(
    to right,
    transparent 0px,
    transparent 8px,
    rgba(255,255,255,0.25) 8px,
    rgba(255,255,255,0.25) 9px
  );
  position: relative;
}

/* Animated shimmer */
.w95-progress-fill.animated::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    90deg,
    rgba(255,255,255,0)   0%,
    rgba(255,255,255,0.25) 50%,
    rgba(255,255,255,0)   100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.4s linear infinite;
}

@keyframes shimmer {
  from { background-position: 200% 0; }
  to   { background-position: -200% 0; }
}

.w95-progress-sublabel {
  font-size: 11px;
  color: var(--w95-dark);
  margin-top: 4px;
}
</style>
