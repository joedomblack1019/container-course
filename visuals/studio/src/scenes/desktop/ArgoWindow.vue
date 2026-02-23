<script setup>
// status: 'degraded' | 'syncing' | 'healthy'
defineProps({
  status: { type: String, default: 'degraded' },
  active: { type: Boolean, default: false },
  width:  { type: Number, default: 690 },
  height: { type: Number, default: 430 },
})

const STATUS_CONFIG = {
  degraded: {
    badge:        'DEGRADED',
    badgeBg:      '#b91c1c',
    syncLabel:    'OutOfSync',
    syncColor:    '#f87171',
    healthLabel:  'Degraded',
    healthColor:  '#f87171',
    revision:     'a3f91c2',
    revisionNote: '← crash: too many replicas',
    events: [
      '09:38 web-deploy-7d9f4b  Back-off restarting failed container',
      '09:39 web-deploy-7d9f4b  Liveness probe failed: connection refused',
      '09:41 web-deploy-7d9f4b  CrashLoopBackOff (4 restarts)',
    ],
  },
  syncing: {
    badge:        'SYNCING',
    badgeBg:      '#1d4ed8',
    syncLabel:    'Syncing',
    syncColor:    '#60a5fa',
    healthLabel:  'Progressing',
    healthColor:  '#60a5fa',
    revision:     'f4e2b9a',
    revisionNote: 'reverting bad deploy...',
    events: [
      '09:47 source-controller   new revision: f4e2b9a detected',
      '09:47 kustomize-controller diff: 1 resource changed',
      '09:47 web-deploy           rolling update: 10 → 3 replicas',
    ],
  },
  healthy: {
    badge:        'HEALTHY',
    badgeBg:      '#15803d',
    syncLabel:    'Synced',
    syncColor:    '#4ade80',
    healthLabel:  'Healthy',
    healthColor:  '#4ade80',
    revision:     'f4e2b9a',
    revisionNote: '✓ reverted successfully',
    events: [
      '09:48 web-deploy           rollout complete: 3/3 replicas ready',
      '09:48 kustomize-controller sync finished in 43s',
      '09:48 health-check         all resources healthy',
    ],
  },
}
</script>

<template>
  <div class="argo-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">⎈</span>
      <span class="win-title">ArgoCD — production</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Menu bar -->
    <div class="argo-menubar">
      <span>App</span><span>View</span><span>Sync</span><span>Help</span>
    </div>

    <!-- Body -->
    <div class="argo-body">

      <!-- App header -->
      <div class="argo-app-header">
        <div class="argo-app-name">
          <span class="argo-ns-tag">production</span>
          <span class="argo-sep">/</span>
          <span class="argo-app-label">k8s-apps</span>
        </div>
        <div class="argo-badge" :style="{ background: STATUS_CONFIG[status].badgeBg }">
          {{ STATUS_CONFIG[status].badge }}
        </div>
      </div>

      <!-- Status grid -->
      <div class="argo-status-grid">

        <div class="argo-status-cell">
          <p class="argo-cell-label">SYNC STATUS</p>
          <p class="argo-cell-value" :style="{ color: STATUS_CONFIG[status].syncColor }">
            {{ STATUS_CONFIG[status].syncLabel }}
          </p>
        </div>

        <div class="argo-status-cell">
          <p class="argo-cell-label">HEALTH STATUS</p>
          <p class="argo-cell-value" :style="{ color: STATUS_CONFIG[status].healthColor }">
            {{ STATUS_CONFIG[status].healthLabel }}
          </p>
        </div>

        <div class="argo-status-cell">
          <p class="argo-cell-label">REVISION</p>
          <p class="argo-cell-value mono">{{ STATUS_CONFIG[status].revision }}</p>
          <p class="argo-cell-note" :style="{ color: STATUS_CONFIG[status].syncColor }">
            {{ STATUS_CONFIG[status].revisionNote }}
          </p>
        </div>

        <div class="argo-status-cell">
          <p class="argo-cell-label">REPOSITORY</p>
          <p class="argo-cell-value mono small">github.com/org/k8s-apps</p>
          <p class="argo-cell-note">branch: main</p>
        </div>

      </div>

      <!-- Syncing progress bar (only shown when syncing) -->
      <div v-if="status === 'syncing'" class="argo-sync-bar-wrap">
        <p class="argo-sync-label">Applying manifests...</p>
        <div class="argo-sync-bar">
          <div class="argo-sync-fill" />
        </div>
      </div>

      <!-- Events log -->
      <div class="argo-events">
        <p class="argo-events-title">EVENTS</p>
        <div class="argo-events-body">
          <div
            v-for="(ev, i) in STATUS_CONFIG[status].events"
            :key="i"
            class="argo-event-row"
          >
            <span class="argo-event-dot" :style="{ background: STATUS_CONFIG[status].syncColor }" />
            {{ ev }}
          </div>
        </div>
      </div>

    </div>

    <!-- Status bar -->
    <div class="argo-statusbar">
      <span>ArgoCD v2.11</span>
      <span>auto-sync: enabled</span>
      <span>self-heal: enabled</span>
    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.argo-window {
  display: flex;
  flex-direction: column;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  outline: 1px solid #000;
  background: #c0c0c0;
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
.win-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

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
  font-family: 'Silkscreen', monospace;
  cursor: default;
}

.win-ctrl-close { font-size: 7px; }

/* ── Menu bar ───────────────────────────────────────────────── */
.argo-menubar {
  display: flex;
  gap: 0;
  background: #c0c0c0;
  border-bottom: 1px solid #808080;
  padding: 1px 4px;
  flex-shrink: 0;
}

.argo-menubar span {
  padding: 2px 10px;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 11px;
  color: #000;
  cursor: default;
}

.argo-menubar span:hover {
  background: #000080;
  color: #fff;
}

/* ── Body ───────────────────────────────────────────────────── */
.argo-body {
  flex: 1;
  background: #1a1a2e;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  overflow: hidden;
}

/* App header */
.argo-app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.argo-app-name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 26px;
  color: #e0e0e0;
}

.argo-ns-tag {
  background: rgba(255,255,255,0.12);
  padding: 2px 12px;
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 2px;
  font-size: 20px;
}

.argo-sep { color: #666; }
.argo-app-label { color: #fff; font-size: 28px; }

.argo-badge {
  font-family: 'Silkscreen', monospace;
  font-size: 16px;
  color: #fff;
  padding: 6px 16px;
  letter-spacing: 0.06em;
  border-radius: 2px;
}

/* Status grid */
.argo-status-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  gap: 8px;
}

.argo-status-cell {
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.1);
  padding: 8px 10px;
}

.argo-cell-label {
  margin: 0 0 6px;
  font-family: 'Silkscreen', monospace;
  font-size: 14px;
  color: #666;
  letter-spacing: 0.08em;
}

.argo-cell-value {
  margin: 0;
  font-family: 'Silkscreen', monospace;
  font-size: 20px;
  color: #e0e0e0;
  line-height: 1.2;
}

.argo-cell-value.mono {
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 26px;
}

.argo-cell-value.small { font-size: 12px; }

.argo-cell-note {
  margin: 4px 0 0;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 21px;
  color: #666;
}

/* Sync progress bar */
.argo-sync-bar-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.argo-sync-label {
  margin: 0;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 15px;
  color: #60a5fa;
}

.argo-sync-bar {
  height: 8px;
  background: rgba(255,255,255,0.1);
  border: 1px solid rgba(255,255,255,0.15);
  overflow: hidden;
}

.argo-sync-fill {
  height: 100%;
  width: 60%;
  background: linear-gradient(90deg, #1d4ed8, #60a5fa);
  animation: sweep 1.8s ease-in-out infinite;
}

@keyframes sweep {
  0%   { width: 10%; margin-left: 0; }
  50%  { width: 60%; margin-left: 20%; }
  100% { width: 10%; margin-left: 90%; }
}

/* Events panel */
.argo-events {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-height: 0;
}

.argo-events-title {
  margin: 0;
  font-family: 'Silkscreen', monospace;
  font-size: 11px;
  color: #555;
  letter-spacing: 0.1em;
}

.argo-events-body {
  flex: 1;
  background: rgba(0,0,0,0.3);
  border: 1px solid rgba(255,255,255,0.08);
  padding: 8px 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  overflow: hidden;
}

.argo-event-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 24px;
  color: #aaa;
  white-space: nowrap;
}

.argo-event-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

/* ── Status bar ─────────────────────────────────────────────── */
.argo-statusbar {
  display: flex;
  gap: 20px;
  padding: 3px 8px;
  background: #c0c0c0;
  border-top: 1px solid #808080;
  font-family: 'Silkscreen', monospace;
  font-size: 9px;
  color: #333;
  flex-shrink: 0;
}
</style>
