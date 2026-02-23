<script setup>
import { computed } from 'vue'
import CmdWindow        from './desktop/CmdWindow.vue'
import ArgoWindow       from './desktop/ArgoWindow.vue'
import GitHistoryWindow from './desktop/GitHistoryWindow.vue'
import PodsWindow       from './desktop/PodsWindow.vue'
import ChatWindow       from './desktop/ChatWindow.vue'
import CEOChatWindow    from './desktop/CEOChatWindow.vue'
import BrowserWindow    from './desktop/BrowserWindow.vue'

import {
  ACTS,
  WINDOW_DEFS,
  ACT_WINDOW_STATE,
  CMD_DISCOVERY,
  CMD_REVERT,
} from './desktop/gitops-incident.js'

const props = defineProps({
  progress: { type: Number, default: 0 },
  title:    { type: String, default: 'GitOps Incident Response' },
})

// ── Act resolution ────────────────────────────────────────────────────────────
const currentAct = computed(() => {
  for (let i = ACTS.length - 1; i >= 0; i--) {
    if (props.progress >= ACTS[i].from) return ACTS[i]
  }
  return ACTS[0]
})

const actFrac = computed(() => {
  const act = currentAct.value
  if (act.to === act.from) return 1
  return Math.min(1, (props.progress - act.from) / (act.to - act.from))
})

const actState = computed(() => ACT_WINDOW_STATE[currentAct.value.id])

// ── Progressive CMD line reveal ───────────────────────────────────────────────
// Discovery lines: reveal during 'discovery' act, then stay fully visible
const discoveryVisibleCount = computed(() => {
  const id = currentAct.value.id
  if (id === 'idle') return 0
  if (id === 'discovery') return Math.ceil(actFrac.value * CMD_DISCOVERY.length)
  return CMD_DISCOVERY.length
})

// Revert lines: reveal during 'revert' act, then stay fully visible
const revertVisibleCount = computed(() => {
  const id = currentAct.value.id
  const revertActs = ['revert', 'reconcile', 'confirm']
  if (!['revert', ...revertActs.slice(1)].includes(id)) return 0
  if (id === 'revert') return Math.ceil(actFrac.value * CMD_REVERT.length)
  return CMD_REVERT.length
})

const cmdLines = computed(() => [
  ...CMD_DISCOVERY.slice(0, discoveryVisibleCount.value),
  ...CMD_REVERT.slice(0, revertVisibleCount.value),
])

// ── Window visibility + z-ordering ───────────────────────────────────────────
// Z-index: focused window = 20, others stack behind in defined order
const Z_ORDER = ['browser', 'cmd', 'argo', 'git', 'pods', 'chat', 'ceochat']

function windowZ(id) {
  if (id === actState.value.focused) return 20
  const idx = Z_ORDER.indexOf(id)
  return Math.max(1, 8 - idx * 2)
}

const isVisible = (id) => actState.value.visible.includes(id)
const isFocused = (id) => actState.value.focused === id

// ── Taskbar items ─────────────────────────────────────────────────────────────
const taskbarItems = computed(() =>
  Object.values(WINDOW_DEFS).filter(w => isVisible(w.id))
)

// ── Act label for status bar ──────────────────────────────────────────────────
const actLabel = computed(() => currentAct.value.label)

// ── Clock (static — looks alive enough) ──────────────────────────────────────
const CLOCK_BY_ACT = {
  idle:           '09:44 AM',
  discovery:      '09:46 AM',
  argocd:         '09:47 AM',
  'git-history':  '09:48 AM',
  revert:         '09:49 AM',
  reconcile:      '09:50 AM',
  confirm:        '09:51 AM',
}
const clock = computed(() => CLOCK_BY_ACT[currentAct.value.id] ?? '09:44 AM')
</script>

<template>
  <!-- The .canvas wrapper in App.vue provides the win98-classic desktop background.
       We just render windows and the taskbar on top of it. -->
  <div class="desktop-scene">

    <!-- ── Windows layer ───────────────────────────────────────── -->

    <!-- CMD window — always mounted, visibility toggled by opacity -->
    <div
      class="win-wrapper"
      :class="isVisible('cmd') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.cmd.pos.x + 'px',
        top:    WINDOW_DEFS.cmd.pos.y + 'px',
        zIndex: windowZ('cmd'),
      }"
    >
      <CmdWindow
        title="Command Prompt"
        :lines="cmdLines"
        :active="isFocused('cmd')"
        :width="WINDOW_DEFS.cmd.pos.w"
        :height="WINDOW_DEFS.cmd.pos.h"
        :show-cursor="true"
      />
    </div>

    <!-- ArgoCD window -->
    <div
      class="win-wrapper"
      :class="isVisible('argo') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.argo.pos.x + 'px',
        top:    WINDOW_DEFS.argo.pos.y + 'px',
        zIndex: windowZ('argo'),
      }"
    >
      <ArgoWindow
        :status="actState.argoStatus ?? 'degraded'"
        :active="isFocused('argo')"
        :width="WINDOW_DEFS.argo.pos.w"
        :height="WINDOW_DEFS.argo.pos.h"
      />
    </div>

    <!-- Git History window -->
    <div
      class="win-wrapper"
      :class="isVisible('git') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.git.pos.x + 'px',
        top:    WINDOW_DEFS.git.pos.y + 'px',
        zIndex: windowZ('git'),
      }"
    >
      <GitHistoryWindow
        :active="isFocused('git')"
        :width="WINDOW_DEFS.git.pos.w"
        :height="WINDOW_DEFS.git.pos.h"
      />
    </div>

    <!-- Pods window -->
    <div
      class="win-wrapper"
      :class="isVisible('pods') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.pods.pos.x + 'px',
        top:    WINDOW_DEFS.pods.pos.y + 'px',
        zIndex: windowZ('pods'),
      }"
    >
      <PodsWindow
        phase="healthy"
        :active="isFocused('pods')"
        :width="WINDOW_DEFS.pods.pos.w"
        :height="WINDOW_DEFS.pods.pos.h"
      />
    </div>

    <!-- Chat window -->
    <div
      class="win-wrapper"
      :class="isVisible('chat') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.chat.pos.x + 'px',
        top:    WINDOW_DEFS.chat.pos.y + 'px',
        zIndex: windowZ('chat'),
      }"
    >
      <ChatWindow
        :active="isFocused('chat')"
        :width="WINDOW_DEFS.chat.pos.w"
        :height="WINDOW_DEFS.chat.pos.h"
      />
    </div>

    <!-- CEO Chat window -->
    <div
      class="win-wrapper"
      :class="isVisible('ceochat') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.ceochat.pos.x + 'px',
        top:    WINDOW_DEFS.ceochat.pos.y + 'px',
        zIndex: windowZ('ceochat'),
      }"
    >
      <CEOChatWindow
        :active="isFocused('ceochat')"
        :width="WINDOW_DEFS.ceochat.pos.w"
        :height="WINDOW_DEFS.ceochat.pos.h"
      />
    </div>

    <!-- Browser window -->
    <div
      class="win-wrapper"
      :class="isVisible('browser') ? 'is-visible' : 'is-hidden'"
      :style="{
        left:   WINDOW_DEFS.browser.pos.x + 'px',
        top:    WINDOW_DEFS.browser.pos.y + 'px',
        zIndex: windowZ('browser'),
      }"
    >
      <BrowserWindow
        :active="isFocused('browser')"
        :width="WINDOW_DEFS.browser.pos.w"
        :height="WINDOW_DEFS.browser.pos.h"
      />
    </div>

    <!-- ── Taskbar ──────────────────────────────────────────────── -->
    <div class="taskbar">

      <!-- Start button -->
      <button class="start-btn">
        <span class="start-logo">⊞</span>
        <span>Start</span>
      </button>

      <div class="taskbar-sep" />

      <!-- Open window buttons -->
      <div class="task-buttons">
        <div
          v-for="w in taskbarItems"
          :key="w.id"
          class="task-btn"
          :class="{ 'task-btn-active': isFocused(w.id) }"
        >
          <span class="task-icon">{{ w.icon }}</span>
          <span class="task-label">{{ w.title }}</span>
        </div>
      </div>

      <div class="taskbar-spacer" />

      <!-- System tray + clock -->
      <div class="tray">
        <span class="tray-icon">💻</span>
        <span class="tray-icon">🛡️</span>
        <span class="tray-icon">📧</span>
        <span class="tray-icon">🔊</span>
        <span class="tray-icon">🌐</span>
        <span class="tray-icon blink">🔔</span>
        <div class="tray-sep" />
        <span class="tray-clock">{{ clock }}</span>
      </div>

    </div>

    <!-- ── Desktop Icons ──────────────────────────────────────────── -->
    <div class="desktop-icons">
      <div class="desktop-icon" style="left: 20px; top: 20px;">
        <div class="icon-img">🖥️</div>
        <div class="icon-label">My Computer</div>
      </div>
      <div class="desktop-icon" style="left: 20px; top: 100px;">
        <div class="icon-img">🗑️</div>
        <div class="icon-label">Recycle Bin</div>
      </div>
      <div class="desktop-icon" style="left: 20px; top: 180px;">
        <div class="icon-img">📄</div>
        <div class="icon-label">URGENT_FIX.txt</div>
      </div>
      <div class="desktop-icon" style="left: 20px; top: 260px;">
        <div class="icon-img">🌐</div>
        <div class="icon-label">Internet Explorer</div>
      </div>
      <div class="desktop-icon" style="left: 120px; top: 20px;">
        <div class="icon-img">🎵</div>
        <div class="icon-label">Winamp</div>
      </div>
      <div class="desktop-icon" style="left: 120px; top: 100px;">
        <div class="icon-img">📧</div>
        <div class="icon-label">Outlook Express</div>
      </div>
    </div>

    <!-- ── Popup Notification ─────────────────────────────────────── -->
    <div v-if="currentAct.id === 'discovery'" class="popup-notification">
      <div class="popup-header">
        <span class="popup-icon">!</span>
        <span class="popup-title">P1 Alert</span>
        <span class="popup-close">✕</span>
      </div>
      <div class="popup-body">
        <strong>Source:</strong> PagerDuty<br>
        <strong>Service:</strong> production/web<br>
        <strong>Issue:</strong> CrashLoopBackOff threshold exceeded<br>
        <br>
        Impact rising in the last 5 minutes. Start rollback workflow now.
      </div>
    </div>

    <!-- ── Act label (bottom-left, above taskbar) ───────────────── -->
    <div class="act-label">
      {{ actLabel }}
    </div>

  </div>
</template>

<style scoped>
/* ── Desktop root ───────────────────────────────────────────── */
.desktop-scene {
  position: relative;
  width: 100%;
  height: 100%;
  /* Background comes from .canvas[data-profile='win98-classic'] in App.vue */
  overflow: hidden;
}

/* ── Window wrappers (positioned absolutely on the desktop) ─── */
.win-wrapper {
  position: absolute;
  /* drop shadow to give depth between windows */
  filter: drop-shadow(3px 3px 6px rgba(0,0,0,0.55));
  transition: opacity 180ms ease, transform 180ms ease;
}

.win-wrapper.is-visible {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.win-wrapper.is-hidden {
  opacity: 0;
  transform: translateY(6px);
  pointer-events: none;
}

/* ── Taskbar ────────────────────────────────────────────────── */
.taskbar {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 40px;
  background: #c0c0c0;
  border-top: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 4px;
  z-index: 100;
  user-select: none;
}

/* Start button */
.start-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 30px;
  padding: 0 10px;
  background: #c0c0c0;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 12px;
  font-weight: 700;
  color: #000;
  cursor: default;
  flex-shrink: 0;
}

.start-logo {
  font-size: 14px;
  color: #000080;
}

.taskbar-sep {
  width: 1px;
  height: 28px;
  background: #808080;
  margin: 0 2px;
  flex-shrink: 0;
}

/* Window task buttons */
.task-buttons {
  display: flex;
  gap: 3px;
  overflow: hidden;
}

.task-btn {
  display: flex;
  align-items: center;
  gap: 5px;
  height: 30px;
  padding: 0 8px;
  min-width: 120px;
  max-width: 180px;
  background: #c0c0c0;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 10px;
  color: #000;
  cursor: default;
  overflow: hidden;
}

.task-btn-active {
  /* "pressed" state for the focused window */
  border-color: #808080 #ffffff #ffffff #808080;
  background: #b0b0b0;
}

.task-icon { font-size: 12px; flex-shrink: 0; }

.task-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
}

.taskbar-spacer { flex: 1; }

/* System tray */
.tray {
  display: flex;
  align-items: center;
  gap: 4px;
  border: 1px solid;
  border-color: #808080 #ffffff #ffffff #808080;
  padding: 0 8px;
  height: 30px;
  flex-shrink: 0;
}

.tray-icon {
  font-size: 12px;
}

.tray-sep {
  width: 1px;
  height: 18px;
  background: #808080;
  margin: 0 3px;
}

.tray-clock {
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 11px;
  color: #000;
  white-space: nowrap;
}

/* ── Act label ──────────────────────────────────────────────── */
.act-label {
  position: absolute;
  bottom: 46px;
  left: 8px;
  font-family: 'Silkscreen', monospace;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.7);
  text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
  pointer-events: none;
  z-index: 50;
  letter-spacing: 0.05em;
}

/* Override act label color for win98-classic to be dark and readable */
[data-profile='win98-classic'] .act-label {
  color: #000;
  text-shadow: 1px 1px 1px rgba(255,255,255,0.8);
}

/* ── Desktop Icons ──────────────────────────────────────────── */
.desktop-icons {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  z-index: 1;
  opacity: 0.72;
}

.desktop-icon {
  position: absolute;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  width: 70px;
  cursor: default;
  user-select: none;
}

.icon-img {
  font-size: 28px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.1);
  border-radius: 2px;
}

.icon-label {
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 9px;
  color: #fff;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
  text-align: center;
  word-wrap: break-word;
  line-height: 1.1;
}

/* Win98 classic desktop icons */
[data-profile='win98-classic'] .icon-label {
  color: #000;
  text-shadow: 1px 1px 1px rgba(255,255,255,0.8);
}

[data-profile='win98-classic'] .icon-img {
  background: transparent;
}

/* ── Popup Notification ─────────────────────────────────────── */
.popup-notification {
  position: absolute;
  bottom: 80px;
  right: 20px;
  width: 280px;
  background: #c0c0c0;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  z-index: 200;
  font-family: 'Tahoma', sans-serif;
}

.popup-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 6px;
  background: linear-gradient(90deg, #000080 0%, #1084d0 100%);
  color: #fff;
  font-size: 11px;
}

.popup-icon {
  font-size: 12px;
}

.popup-title {
  flex: 1;
  font-weight: bold;
}

.popup-close {
  cursor: default;
  font-size: 10px;
}

.popup-body {
  padding: 8px;
  font-size: 11px;
  color: #000;
  line-height: 1.3;
  background: #fff;
}

/* ── Blinking notification icon ─────────────────────────────── */
.tray-icon.blink {
  animation: blink 1s ease-in-out infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0.3; }
}
</style>
