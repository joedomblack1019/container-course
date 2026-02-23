<script setup lang="ts">
const props = withDefaults(defineProps<{ activeStep?: number }>(), {
  activeStep: 1,
})

const steps = [
  { key: "git", label: "1. Git Commit", detail: "desired state updated in repo" },
  { key: "detect", label: "2. Argo Detects Diff", detail: "target revision diverges from cluster" },
  { key: "sync", label: "3. Sync Apply", detail: "kustomize output applied to cluster" },
  { key: "verify", label: "4. Health + Self-Heal", detail: "drift corrected back to Git truth" },
]
</script>

<template>
  <div class="loop-grid">
    <div class="node" :class="{ active: props.activeStep >= 1 }">
      <div class="node-title">{{ steps[0].label }}</div>
      <div class="node-detail">{{ steps[0].detail }}</div>
    </div>
    <div class="connector horizontal" :class="{ active: props.activeStep >= 2 }">-></div>
    <div class="node" :class="{ active: props.activeStep >= 2 }">
      <div class="node-title">{{ steps[1].label }}</div>
      <div class="node-detail">{{ steps[1].detail }}</div>
    </div>
    <div class="connector vertical" :class="{ active: props.activeStep >= 3 }">|</div>
    <div class="node" :class="{ active: props.activeStep >= 4 }">
      <div class="node-title">{{ steps[3].label }}</div>
      <div class="node-detail">{{ steps[3].detail }}</div>
    </div>
    <div class="connector horizontal left" :class="{ active: props.activeStep >= 4 }"><-</div>
    <div class="node" :class="{ active: props.activeStep >= 3 }">
      <div class="node-title">{{ steps[2].label }}</div>
      <div class="node-detail">{{ steps[2].detail }}</div>
    </div>
  </div>
</template>

<style scoped>
.loop-grid {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  grid-template-rows: auto auto auto;
  gap: 12px;
  align-items: center;
  max-width: 980px;
  margin: 20px auto 0;
}

.node {
  border: 2px solid #9ca3af;
  border-radius: 12px;
  padding: 16px 18px;
  background: #f3f4f6;
  color: #111827;
  min-height: 110px;
  transition: all 0.25s ease;
}

.node.active {
  border-color: #1d4ed8;
  background: #dbeafe;
}

.node:nth-child(1) { grid-column: 1; grid-row: 1; }
.node:nth-child(3) { grid-column: 3; grid-row: 1; }
.node:nth-child(5) { grid-column: 3; grid-row: 3; }
.node:nth-child(7) { grid-column: 1; grid-row: 3; }

.connector {
  font-weight: 700;
  font-size: 1.1rem;
  color: #6b7280;
  text-align: center;
}

.connector.active {
  color: #1d4ed8;
}

.connector.horizontal { grid-column: 2; grid-row: 1; }
.connector.vertical { grid-column: 3; grid-row: 2; }
.connector.left { grid-column: 2; grid-row: 3; }

.node-title {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 8px;
  line-height: 1.2;
}

.node-detail {
  font-size: 0.95rem;
  line-height: 1.3;
}
</style>

