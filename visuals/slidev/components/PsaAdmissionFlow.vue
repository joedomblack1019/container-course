<script setup lang="ts">
const props = withDefaults(defineProps<{
  activeStep?: number
  compact?: boolean
}>(), {
  activeStep: 1,
  compact: false,
})

const steps = [
  { key: "namespace",   label: "Namespace Labels", detail: "enforce/audit/warn level set" },
  { key: "validation",  label: "Admission Check",  detail: "pod spec evaluated against PSS" },
  { key: "result",      label: "Result",            detail: "admitted or denied with reason" },
  { key: "remediation", label: "Remediation",       detail: "set securityContext and re-apply" },
]
</script>

<template>
  <div class="admission-steps" :class="{ compact }">
    <div
      v-for="(step, index) in steps"
      :key="step.key"
      class="step"
      :class="{ active: index + 1 <= props.activeStep }"
    >
      <div class="step-index">{{ index + 1 }}</div>
      <div class="step-copy">
        <div class="step-label">{{ step.label }}</div>
        <div class="step-detail">{{ step.detail }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ── Full mode (default) ─────────────────────────────────── */
.admission-steps {
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 100%;
  height: calc(100% - 48px); /* fill below h2 */
  min-height: 240px;
  margin-top: 10px;
}

.step {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
  max-height: 100px;
  border: 2px solid #9ca3af;
  background: #f3f4f6;
  color: #111827;
  padding: 14px 18px;
  transition: background 0.35s ease, border-color 0.35s ease, transform 0.2s ease, box-shadow 0.25s ease;
}

.step.active {
  border-color: #b45309;
  background: #fef3c7;
  transform: translateX(3px);
  box-shadow: -3px 0 0 #b45309;
}

.step-index {
  width: 38px;
  height: 38px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1.1rem;
  flex-shrink: 0;
  background: #e5e7eb;
  color: #6b7280;
  transition: background 0.35s ease, color 0.35s ease;
}

.step.active .step-index {
  background: #f59e0b;
  color: #111827;
}

.step-copy {
  flex: 1;
}

.step-label {
  font-size: 1.15rem;
  font-weight: 700;
  line-height: 1.2;
}

.step-detail {
  font-size: 0.82rem;
  margin-top: 4px;
  color: #4b5563;
  transition: color 0.35s ease;
}

.step.active .step-detail {
  color: #92400e;
}

/* ── Compact mode (used when sharing slide with a dialog) ── */
.admission-steps.compact {
  gap: 6px;
  height: auto;
  min-height: unset;
  margin-top: 6px;
  margin-bottom: 10px;
}

.admission-steps.compact .step {
  flex: none;
  padding: 8px 14px;
  gap: 12px;
}

.admission-steps.compact .step-index {
  width: 26px;
  height: 26px;
  font-size: 0.85rem;
}

.admission-steps.compact .step-label {
  font-size: 0.9rem;
}

.admission-steps.compact .step-detail {
  font-size: 0.72rem;
  margin-top: 2px;
}
</style>
