<script setup>
// phase: 'crashing' | 'recovering' | 'healthy'
defineProps({
  phase:  { type: String,  default: 'healthy' },
  active: { type: Boolean, default: false },
  width:  { type: Number,  default: 1000 },
  height: { type: Number,  default: 320 },
})

// Pod states per phase
const PODS = {
  crashing: [
    { name: 'web-deploy-7d9f4b-xkj2p',   ready: '0/1', status: 'CrashLoopBackOff', restarts: '4',  age: '8m',  bad: true  },
    { name: 'redis-649c8d77b-r9xzp',      ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
    { name: 'postgres-84fd5c89b-ppqt8',   ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
  ],
  recovering: [
    { name: 'web-deploy-7d9f4b-xkj2p',   ready: '0/1', status: 'Terminating',       restarts: '4',  age: '9m',  bad: true  },
    { name: 'web-deploy-f4e2b9a-m7vwk',  ready: '0/1', status: 'ContainerCreating', restarts: '0',  age: '5s',  bad: false },
    { name: 'redis-649c8d77b-r9xzp',      ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
    { name: 'postgres-84fd5c89b-ppqt8',   ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
  ],
  healthy: [
    { name: 'web-deploy-f4e2b9a-m7vwk',  ready: '1/1', status: 'Running',           restarts: '0',  age: '42s', bad: false },
    { name: 'redis-649c8d77b-r9xzp',      ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
    { name: 'postgres-84fd5c89b-ppqt8',   ready: '1/1', status: 'Running',           restarts: '0',  age: '2d',  bad: false },
  ],
}
</script>

<template>
  <div class="pods-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">🐳</span>
      <span class="win-title">kubectl — production</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Terminal body -->
    <div class="pods-body">

      <!-- Header command -->
      <div class="pods-cmd">
        <span class="pods-prompt">$ </span>
        <span class="pods-input">kubectl get pods -n production --watch</span>
      </div>

      <!-- Column header -->
      <div class="pods-row pods-header-row">
        <span class="col-name">NAME</span>
        <span class="col-ready">READY</span>
        <span class="col-status">STATUS</span>
        <span class="col-restarts">RESTARTS</span>
        <span class="col-age">AGE</span>
      </div>

      <!-- Pod rows -->
      <div
        v-for="pod in PODS[phase]"
        :key="pod.name"
        class="pods-row"
        :class="{
          'row-bad':  pod.bad && pod.status === 'CrashLoopBackOff',
          'row-warn': pod.bad && pod.status !== 'CrashLoopBackOff',
          'row-ok':   !pod.bad,
        }"
      >
        <span class="col-name">{{ pod.name }}</span>
        <span class="col-ready">{{ pod.ready }}</span>
        <span class="col-status">{{ pod.status }}</span>
        <span class="col-restarts">{{ pod.restarts }}</span>
        <span class="col-age">{{ pod.age }}</span>
      </div>

      <!-- Trailing cursor -->
      <div class="pods-cmd">
        <span class="pods-prompt">$ </span>
        <span class="pods-cursor" />
      </div>

    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.pods-window {
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
  flex-shrink: 0;
  user-select: none;
}

.win-titlebar.inactive {
  background: #808080;
  color: #d4d0c8;
}

.win-icon { font-size: 10px; flex-shrink: 0; }
.win-title { flex: 1; }
.win-controls { display: flex; gap: 2px; flex-shrink: 0; }

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
  cursor: default;
}

.win-ctrl-close { font-size: 7px; }

/* ── Terminal body ──────────────────────────────────────────── */
.pods-body {
  flex: 1;
  background: #0c0c0c;
  padding: 12px 18px;
  font-family: var(--mono-font, 'VT323', 'Courier New', monospace);
  font-size: 30px;
  line-height: 1.45;
  overflow: hidden;
}

.pods-cmd {
  display: flex;
  align-items: baseline;
  margin-bottom: 4px;
}

.pods-prompt {
  color: #39ff14;
  text-shadow: 0 0 4px #1a7a08;
  flex-shrink: 0;
}

.pods-input {
  color: #39ff14;
  text-shadow: 0 0 4px #1a7a08;
}

/* ── Table rows ─────────────────────────────────────────────── */
.pods-row {
  display: flex;
  align-items: center;
  padding: 1px 0;
  white-space: pre;
}

.pods-header-row {
  color: #c0c0c0;
  margin-bottom: 2px;
}

/* Column widths */
.col-name     { width: 560px; flex-shrink: 0; }
.col-ready    { width: 95px;  flex-shrink: 0; }
.col-status   { width: 300px; flex-shrink: 0; }
.col-restarts { width: 150px; flex-shrink: 0; }
.col-age      { width: 90px;  flex-shrink: 0; }

/* Row states */
.row-bad  { color: #ff6b5d; text-shadow: 0 0 4px #aa1100; }
.row-warn { color: #ffb300; }
.row-ok   { color: #c0c0c0; }

/* Running status highlight */
.row-ok .col-status { color: #39ff14; text-shadow: 0 0 3px #1a7a08; }

/* ── Blinking cursor ────────────────────────────────────────── */
.pods-cursor {
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
