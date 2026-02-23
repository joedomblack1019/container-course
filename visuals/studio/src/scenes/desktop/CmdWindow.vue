<script setup>
defineProps({
  title:        { type: String,  default: 'Command Prompt' },
  lines:        { type: Array,   default: () => [] },
  active:       { type: Boolean, default: true },
  showCursor:   { type: Boolean, default: true },
  width:        { type: Number,  default: 740 },
  height:       { type: Number,  default: 390 },
})
</script>

<template>
  <div class="cmd-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">▪</span>
      <span class="win-title">{{ title }}</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Terminal body -->
    <div class="cmd-body">
      <div
        v-for="(line, i) in lines"
        :key="i"
        class="cmd-line"
        :class="line.type"
      >
        <span v-if="line.type === 'input'" class="cmd-prompt">$ </span>
        <span class="cmd-text">{{ line.text }}</span>
      </div>

      <!-- Blinking cursor after last line -->
      <div v-if="showCursor" class="cmd-line output">
        <span class="cmd-prompt">$ </span>
        <span class="cmd-cursor" />
      </div>
    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.cmd-window {
  display: flex;
  flex-direction: column;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  outline: 1px solid #000;
  background: #000;
  overflow: hidden;
  flex-shrink: 0;
}

.win-titlebar {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 22px;
  padding: 0 2px 0 4px;
  background: linear-gradient(90deg, #000080 0%, #1084d0 100%);
  color: #fff;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 11px;
  font-weight: 400;
  flex-shrink: 0;
  user-select: none;
}

.win-titlebar.inactive {
  background: #808080;
  color: #d4d0c8;
}

.win-icon {
  font-size: 10px;
  flex-shrink: 0;
}

.win-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.win-controls {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.win-ctrl {
  width: 16px;
  height: 14px;
  background: #c0c0c0;
  color: #000;
  border: 1px solid;
  border-color: #fff #808080 #808080 #fff;
  font-size: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-family: 'Silkscreen', monospace;
  cursor: default;
}

.win-ctrl-close { font-size: 7px; }

/* ── Terminal body ──────────────────────────────────────────── */
.cmd-body {
  flex: 1;
  background: #0c0c0c;
  padding: 12px 16px;
  overflow: hidden;
  font-family: var(--mono-font, 'VT323', 'Courier New', monospace);
  font-size: 28px;
  line-height: 1.4;
}

.cmd-line {
  display: flex;
  align-items: baseline;
  min-height: 1.4em;
  white-space: pre;
}

.cmd-prompt {
  color: #39ff14;
  text-shadow: 0 0 4px #1a7a08;
  flex-shrink: 0;
}

.cmd-text { }

/* Line type colors */
.cmd-line.input   .cmd-text { color: #39ff14; text-shadow: 0 0 4px #1a7a08; }
.cmd-line.output  .cmd-text { color: #c0c0c0; }
.cmd-line.error   .cmd-text { color: #ff6b5d; text-shadow: 0 0 4px #aa1100; }
.cmd-line.success .cmd-text { color: #39ff14; font-weight: bold; text-shadow: 0 0 6px #1a7a08; }
.cmd-line.comment .cmd-text { color: #666; font-style: italic; }

/* Input lines — prompt is green */
.cmd-line.input .cmd-prompt { color: #39ff14; }

/* ── Blinking cursor ────────────────────────────────────────── */
.cmd-cursor {
  display: inline-block;
  width: 0.55em;
  height: 1.1em;
  background: #39ff14;
  box-shadow: 0 0 5px #1a7a08;
  animation: blink 1.1s step-end infinite;
  vertical-align: text-bottom;
}

@keyframes blink {
  0%, 49% { opacity: 1; }
  50%, 100% { opacity: 0; }
}
</style>
