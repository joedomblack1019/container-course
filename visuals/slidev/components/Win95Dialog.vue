<script setup lang="ts">
const props = withDefaults(defineProps<{
  title?: string
  message?: string
  detail?: string
  type?: 'info' | 'warning' | 'error' | 'question'
  buttons?: string[]
  activeButton?: number
}>(), {
  title: 'Dialog',
  message: '',
  type: 'info',
  buttons: () => ['OK'],
  activeButton: 0,
})

const icons: Record<string, string> = {
  info:     '🛈',
  warning:  '⚠',
  error:    '✖',
  question: '?',
}

const iconColors: Record<string, string> = {
  info:     '#000080',
  warning:  '#000000',
  error:    '#cc0000',
  question: '#000080',
}
</script>

<template>
  <div class="w95-dialog-outer">
    <Win95Window :title="title" :icon="icons[type]" class="w95-dialog-window">
      <div class="w95-dialog-body">
        <!-- Icon + message row -->
        <div class="w95-dialog-content">
          <div class="w95-dialog-icon" :style="{ color: iconColors[type] }">
            <span class="icon-char">{{ icons[type] }}</span>
          </div>
          <div class="w95-dialog-text">
            <div class="w95-dialog-message">{{ message }}</div>
            <div v-if="detail" class="w95-dialog-detail">{{ detail }}</div>
          </div>
        </div>

        <hr class="w95-divider" />

        <!-- Buttons row -->
        <div class="w95-dialog-buttons">
          <button
            v-for="(btn, i) in buttons"
            :key="btn"
            class="w95-button"
            :class="{ primary: i === activeButton }"
          >
            {{ btn }}
          </button>
        </div>
      </div>
    </Win95Window>
  </div>
</template>

<style scoped>
.w95-dialog-outer {
  display: flex;
  align-items: center;
  justify-content: center;
}

.w95-dialog-window {
  min-width: 300px;
  max-width: 480px;
}

.w95-dialog-body {
  padding: 16px 16px 12px;
}

.w95-dialog-content {
  display: flex;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 16px;
}

.w95-dialog-icon {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-char {
  font-size: 28px;
  line-height: 1;
  font-weight: 700;
}

.w95-dialog-text {
  flex: 1;
}

.w95-dialog-message {
  font-family: var(--w95-font);
  font-size: 13px;
  color: var(--w95-black);
  line-height: 1.5;
}

.w95-dialog-detail {
  font-family: var(--w95-mono-font);
  font-size: 11px;
  color: var(--w95-dark);
  margin-top: 8px;
  padding: 6px 8px;
  background: var(--w95-white);
  box-shadow: var(--w95-inset);
  line-height: 1.6;
  white-space: pre-wrap;
}

.w95-divider {
  border: none;
  border-top: 1px solid var(--w95-gray);
  border-bottom: 1px solid var(--w95-white);
  margin: 0 0 12px 0;
}

.w95-dialog-buttons {
  display: flex;
  justify-content: center;
  gap: 8px;
}

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
}

.w95-button.primary {
  outline: 1px solid var(--w95-black);
  outline-offset: -3px;
}

.w95-button:active {
  box-shadow: var(--w95-inset);
}
</style>
