<script setup lang="ts">
withDefaults(defineProps<{
  label?: string
  disabled?: boolean
  primary?: boolean
  small?: boolean
}>(), {
  disabled: false,
  primary: false,
  small: false,
})

defineEmits<{ click: [] }>()
</script>

<template>
  <button
    class="w95-button"
    :class="{ primary, small, disabled }"
    :disabled="disabled"
    @click="$emit('click')"
  >
    <slot>{{ label }}</slot>
  </button>
</template>

<style scoped>
.w95-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 75px;
  height: 23px;
  padding: 0 12px;
  background: var(--w95-silver);
  border: none;
  cursor: pointer;
  font-family: var(--w95-font);
  font-size: 12px;
  font-weight: 500;
  color: var(--w95-black);
  box-shadow: var(--w95-raised);
  user-select: none;
  white-space: nowrap;
}

.w95-button:hover:not(:disabled) {
  background: var(--w95-light);
}

.w95-button:active:not(:disabled),
.w95-button.active {
  box-shadow: var(--w95-inset);
  padding-top: 1px;
  padding-left: 13px;
}

.w95-button.primary {
  outline: 1px solid var(--w95-black);
  outline-offset: -3px;
}

.w95-button.small {
  min-width: 40px;
  height: 18px;
  font-size: 11px;
  padding: 0 6px;
}

.w95-button.disabled,
.w95-button:disabled {
  color: var(--w95-gray);
  cursor: default;
  box-shadow: var(--w95-raised);
  text-shadow: 1px 1px 0 var(--w95-white);
}
</style>
