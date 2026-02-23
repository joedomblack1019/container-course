<script setup>
defineProps({
  active: { type: Boolean, default: false },
  width:  { type: Number, default: 800 },
  height: { type: Number, default: 600 },
})

// Investigation references shown during the incident
const BROWSER_TABS = [
  'Runbook - CrashLoopBackOff triage',
  'ArgoCD - degraded app checklist',
  'Kubernetes - deployment rollback',
  'Git - safe revert procedure',
  'Incident docs - comms template'
]

const SO_CONTENT = `
Internal Runbook: CrashLoopBackOff During GitOps Deploy

Checklist

1) Confirm scope
   kubectl get pods -n production

2) Verify controller status
   argocd app get web-app

3) Inspect recent config changes
   git log --oneline -- deploy/production

4) Validate suspect revision
   kubectl describe pod <failing-pod>

5) Recover quickly
   git revert <bad-sha> --no-edit
   git push origin main

6) Confirm stabilization
   kubectl get pods -n production --watch

Notes
- Prefer revert over manual hot edits.
- Capture timeline for the post-incident review.
`
</script>

<template>
  <div class="browser-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">🌐</span>
      <span class="win-title">Internet Explorer - Runbook</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Menu bar -->
    <div class="browser-menubar">
      <span>File</span><span>Edit</span><span>View</span><span>Go</span><span>Favorites</span><span>Help</span>
    </div>

    <!-- Toolbar -->
    <div class="browser-toolbar">
      <button class="toolbar-btn">◀</button>
      <button class="toolbar-btn">▶</button>
      <button class="toolbar-btn">H</button>
      <button class="toolbar-btn">R</button>
      <div class="address-bar">
        <span class="address-text">https://intranet/runbooks/crashloopbackoff-gitops</span>
      </div>
    </div>

    <!-- Tabs -->
    <div class="browser-tabs">
      <div
        v-for="(tab, i) in BROWSER_TABS"
        :key="i"
        class="browser-tab"
        :class="{ active: i === 0 }"
      >
        {{ tab.substring(0, 25) }}{{ tab.length > 25 ? '...' : '' }}
      </div>
    </div>

    <!-- Browser content -->
    <div class="browser-content">
      <pre class="so-content">{{ SO_CONTENT }}</pre>
    </div>

    <!-- Status bar -->
    <div class="browser-statusbar">
      <span>Done</span>
      <span>Internet Zone</span>
    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.browser-window {
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

/* ── Menu bar ───────────────────────────────────────────────── */
.browser-menubar {
  display: flex;
  gap: 0;
  background: #c0c0c0;
  border-bottom: 1px solid #808080;
  padding: 1px 4px;
  flex-shrink: 0;
}

.browser-menubar span {
  padding: 2px 8px;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 10px;
  color: #000;
  cursor: default;
}

/* ── Toolbar ────────────────────────────────────────────────── */
.browser-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
  background: #c0c0c0;
  border-bottom: 1px solid #808080;
  flex-shrink: 0;
}

.toolbar-btn {
  width: 24px;
  height: 22px;
  background: #c0c0c0;
  border: 1px solid;
  border-color: #fff #808080 #808080 #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  cursor: default;
}

.address-bar {
  flex: 1;
  background: #fff;
  border: 1px solid;
  border-color: #808080 #fff #fff #808080;
  padding: 2px 6px;
  margin-left: 8px;
}

.address-text {
  font-family: 'Tahoma', sans-serif;
  font-size: 13px;
  color: #000;
}

/* ── Tabs ───────────────────────────────────────────────────── */
.browser-tabs {
  display: flex;
  background: #c0c0c0;
  border-bottom: 1px solid #808080;
  overflow: hidden;
}

.browser-tab {
  padding: 4px 8px;
  border-right: 1px solid #808080;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 11px;
  color: #000;
  background: #e0e0e0;
  cursor: default;
  max-width: 150px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.browser-tab.active {
  background: #fff;
  border-bottom: 1px solid #fff;
}

/* ── Content ────────────────────────────────────────────────── */
.browser-content {
  flex: 1;
  background: #fff;
  overflow: auto;
  padding: 8px;
}

.so-content {
  font-family: 'Tahoma', Arial, sans-serif;
  font-size: 14px;
  line-height: 1.4;
  color: #000;
  margin: 0;
  white-space: pre-wrap;
}

/* ── Status bar ─────────────────────────────────────────────── */
.browser-statusbar {
  display: flex;
  gap: 20px;
  padding: 3px 8px;
  background: #c0c0c0;
  border-top: 1px solid #808080;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 9px;
  color: #000;
  flex-shrink: 0;
}
</style>
