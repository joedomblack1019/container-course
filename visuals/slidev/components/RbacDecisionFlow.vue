<script setup lang="ts">
const props = withDefaults(defineProps<{ activeStep?: number }>(), {
  activeStep: 1,
})

const steps = [
  { key: "subject",  label: "Subject",    detail: "User or ServiceAccount" },
  { key: "binding",  label: "Binding",    detail: "RoleBinding / ClusterRoleBinding" },
  { key: "role",     label: "Role Rules", detail: "verbs + resources + apiGroups" },
  { key: "decision", label: "Decision",   detail: "allow or deny" },
]
</script>

<template>
  <div class="rbac-flow">
    <div
      v-for="(step, index) in steps"
      :key="step.key"
      class="step-wrap"
    >
      <div class="step" :class="{ active: index + 1 <= props.activeStep }">
        <div class="step-num">{{ index + 1 }}</div>
        <div class="step-body">
          <div class="step-label">{{ step.label }}</div>
          <div class="step-detail">{{ step.detail }}</div>
        </div>
      </div>
      <div
        v-if="index < steps.length - 1"
        class="arrow"
        :class="{ active: index + 1 < props.activeStep }"
      >
        &#x25BA;
      </div>
    </div>
  </div>
</template>

<style scoped>
.rbac-flow {
  display: flex;
  align-items: stretch;
  justify-content: stretch;
  gap: 0;
  width: 100%;
  height: calc(100% - 48px); /* fill below the h2 heading */
  min-height: 260px;
  margin-top: 12px;
}

.step-wrap {
  display: flex;
  align-items: center;
  flex: 1;
  gap: 0;
}

/* grow the box to fill its slot */
.step {
  flex: 1;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  text-align: center;
  border: 2px solid #9ca3af;
  background: #f3f4f6;
  color: #1f2937;
  padding: 18px 14px;
  transition: background 0.35s ease, border-color 0.35s ease, transform 0.25s ease, box-shadow 0.25s ease;
  position: relative;
}

.step.active {
  border-color: #0f766e;
  background: #ccfbf1;
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(15, 118, 110, 0.2);
}

.step-num {
  width: 38px;
  height: 38px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1.1rem;
  background: #e5e7eb;
  color: #6b7280;
  flex-shrink: 0;
  transition: background 0.35s ease, color 0.35s ease;
}

.step.active .step-num {
  background: #0f766e;
  color: #ffffff;
}

.step-body {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: center;
}

.step-label {
  font-size: 1.25rem;
  font-weight: 700;
  line-height: 1.2;
}

.step-detail {
  font-size: 0.88rem;
  line-height: 1.3;
  color: #4b5563;
  transition: color 0.35s ease;
}

.step.active .step-detail {
  color: #134e4a;
}

/* arrow connector */
.arrow {
  font-size: 1.4rem;
  color: #d1d5db;
  padding: 0 6px;
  flex-shrink: 0;
  transition: color 0.35s ease;
  line-height: 1;
}

.arrow.active {
  color: #0f766e;
}
</style>
