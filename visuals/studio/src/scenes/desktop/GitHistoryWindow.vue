<script setup>
import { GIT_COMMITS } from './gitops-incident.js'

defineProps({
  active: { type: Boolean, default: false },
  width:  { type: Number, default: 840 },
  height: { type: Number, default: 460 },
})
</script>

<template>
  <div class="git-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">📋</span>
      <span class="win-title">Git History — main</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Toolbar (fake, for Win98 app feel) -->
    <div class="git-toolbar">
      <div class="git-toolbar-btn">◀</div>
      <div class="git-toolbar-btn">▶</div>
      <div class="git-toolbar-sep" />
      <div class="git-toolbar-btn">⟳</div>
      <div class="git-toolbar-sep" />
      <div class="git-branch-pill">
        <span class="git-branch-icon">⎇</span>
        <span>main</span>
      </div>
      <div class="git-toolbar-spacer" />
      <div class="git-search-box">
        <span class="git-search-icon">🔍</span>
        <span class="git-search-text">Search commits...</span>
      </div>
    </div>

    <!-- Column headers -->
    <div class="git-col-headers">
      <span class="git-col-sha">SHA</span>
      <span class="git-col-msg">Commit Message</span>
      <span class="git-col-author">Author</span>
      <span class="git-col-time">When</span>
    </div>

    <!-- Commit rows -->
    <div class="git-commits-body">
      <div
        v-for="commit in GIT_COMMITS"
        :key="commit.sha"
        class="git-commit-row"
        :class="{ bad: commit.bad }"
      >
        <span class="git-col-sha">
          <span class="git-sha-pill" :class="{ 'sha-bad': commit.bad }">
            {{ commit.sha }}
          </span>
        </span>
        <span class="git-col-msg">
          <span v-if="commit.bad" class="git-bad-icon">⚠</span>
          {{ commit.msg }}
          <span v-if="commit.bad" class="git-bad-tag">← CrashLoopBackOff</span>
        </span>
        <span class="git-col-author">{{ commit.author }}</span>
        <span class="git-col-time">{{ commit.time }}</span>
      </div>
    </div>

    <!-- Status bar -->
    <div class="git-statusbar">
      <span>{{ GIT_COMMITS.length }} commits</span>
      <span>branch: main</span>
      <span>remote: origin</span>
    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.git-window {
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
  cursor: default;
}

.win-ctrl-close { font-size: 7px; }

/* ── Toolbar ────────────────────────────────────────────────── */
.git-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
  background: #c0c0c0;
  border-bottom: 1px solid #808080;
  flex-shrink: 0;
}

.git-toolbar-btn {
  width: 24px;
  height: 22px;
  background: #c0c0c0;
  border: 1px solid;
  border-color: #fff #808080 #808080 #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: #333;
  cursor: default;
}

.git-toolbar-sep {
  width: 1px;
  height: 20px;
  background: #808080;
  margin: 0 3px;
}

.git-toolbar-spacer { flex: 1; }

.git-branch-pill {
  display: flex;
  align-items: center;
  gap: 4px;
  background: #fff;
  border: 1px solid;
  border-color: #808080 #fff #fff #808080;
  padding: 1px 8px;
  font-family: 'Silkscreen', monospace;
  font-size: 10px;
  color: #000080;
}

.git-branch-icon { font-size: 10px; }

.git-search-box {
  display: flex;
  align-items: center;
  gap: 4px;
  background: #fff;
  border: 1px solid;
  border-color: #808080 #fff #fff #808080;
  padding: 1px 8px;
  width: 160px;
}

.git-search-icon { font-size: 10px; }

.git-search-text {
  font-family: 'Silkscreen', monospace;
  font-size: 9px;
  color: #555;
}

/* ── Column headers ─────────────────────────────────────────── */
.git-col-headers {
  display: flex;
  padding: 6px 12px;
  background: #d4d0c8;
  border-bottom: 1px solid #808080;
  font-family: 'Silkscreen', monospace;
  font-size: 13px;
  color: #333;
  letter-spacing: 0.04em;
  flex-shrink: 0;
}

/* ── Shared column widths ───────────────────────────────────── */
.git-col-sha    { width: 120px; flex-shrink: 0; }
.git-col-msg    { flex: 1; overflow: hidden; }
.git-col-author { width: 80px; flex-shrink: 0; }
.git-col-time   { width: 130px; flex-shrink: 0; text-align: right; }

/* ── Commits list ───────────────────────────────────────────── */
.git-commits-body {
  flex: 1;
  background: #fff;
  overflow: hidden;
}

.git-commit-row {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #e8e8e8;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 24px;
  color: #222;
  transition: background 0.15s;
}

.git-commit-row.bad {
  background: #fff0ef;
  border-left: 3px solid #dc2626;
  animation: bad-pulse 2s ease-in-out infinite;
}

@keyframes bad-pulse {
  0%, 100% { background: #fff0ef; }
  50%       { background: #ffe0de; }
}

.git-sha-pill {
  display: inline-block;
  background: #f0f0f0;
  border: 1px solid #ccc;
  padding: 2px 8px;
  font-family: var(--mono-font, 'VT323', monospace);
  font-size: 20px;
  color: #1d4ed8;
  border-radius: 2px;
}

.git-sha-pill.sha-bad {
  background: #fee2e2;
  border-color: #dc2626;
  color: #dc2626;
}

.git-bad-icon {
  color: #dc2626;
  margin-right: 4px;
}

.git-bad-tag {
  margin-left: 12px;
  font-size: 20px;
  color: #dc2626;
  font-style: italic;
}

/* ── Status bar ─────────────────────────────────────────────── */
.git-statusbar {
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
