<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  activeStep?: number
  title?: string
}>(), {
  activeStep: 1,
  title: 'Reconciliation Sequence',
})

const steps = [
  {
    id: '01',
    label: 'Commit to Git',
    detail: 'You push desired state into the Git repository.',
    cmd: 'git commit -m "update" && git push',
  },
  {
    id: '02',
    label: 'Webhook / Poll',
    detail: 'Webhook or polling detects new commits in the repository.',
    cmd: 'source-controller: revision detected',
  },
  {
    id: '03',
    label: 'Compute Diff',
    detail: 'Controller diffs desired state against live cluster resources.',
    cmd: 'kustomize-controller: diff desired vs live',
  },
  {
    id: '04',
    label: 'Apply Changes',
    detail: 'Controller applies new manifests to converge cluster state.',
    cmd: 'kubectl apply --server-side -f manifests/',
  },
  {
    id: '05',
    label: 'Verify Health',
    detail: 'Health checks validate workloads and monitor drift continuously.',
    cmd: 'health checks: passing, drift: none',
  },
  {
    id: '06',
    label: 'Loop Continues',
    detail: 'Status updates visible to operators. Loop repeats immediately.',
    cmd: 'status: synced @ revision 9d4f2c7',
  },
]

// ── Ellipse geometry (in SVG viewBox-0-0-100-100 units = % of container) ──────
// Using preserveAspectRatio="none" on the SVG, so these % coords map 1-to-1
// with absolute CSS `left`/`top` positioning on the node elements.
const CX = 50, CY = 50, RX = 34, RY = 24

// Steps start at 9-o'clock (left, 180°) and go counterclockwise in screen space.
// This matches the SVG path direction: M (CX-RX, CY) → A … → (CX+RX, CY) → A … → (CX-RX, CY)
const STEP_ANGLES = [180, 240, 300, 0, 60, 120]

const nodePositions = STEP_ANGLES.map(deg => {
  const r = (deg * Math.PI) / 180
  return { x: CX + RX * Math.cos(r), y: CY + RY * Math.sin(r) }
})

// Ellipse circumference via Ramanujan approximation
const _h = ((RX - RY) / (RX + RY)) ** 2
const CIRC = Math.PI * (RX + RY) * (1 + (3 * _h) / (10 + Math.sqrt(4 - 3 * _h)))
// ≈ 183.6 — used for stroke-dasharray and dashoffset

const activeIdx = computed(() => Math.max(0, Math.min(props.activeStep - 1, steps.length - 1)))
const current   = computed(() => steps[activeIdx.value])

// Arc fill length (grows from 0 → CIRC as steps complete)
const arcLen = computed(() => (props.activeStep / steps.length) * CIRC)

type NodeState = 'done' | 'active' | 'pending'
const stateOf = (i: number): NodeState => {
  if (i < activeIdx.value) return 'done'
  if (i === activeIdx.value) return 'active'
  return 'pending'
}

// Win98 segmented progress bar percentage
const pct = computed(() => Math.round((props.activeStep / steps.length) * 100))
</script>

<template>
  <div class="rm-root w95-desktop-bg">
    <div class="rm-bezel w95-raised">

      <!-- Win95 title bar -->
      <div class="rm-titlebar">
        <span class="rm-titlebar-icon">🔄</span>
        <span class="rm-titlebar-text">GitOps Monitor.exe</span>
        <div class="rm-titlebar-btns">
          <button>_</button>
          <button>□</button>
          <button>✕</button>
        </div>
      </div>

      <!-- Main body grid -->
      <div class="rm-body">

        <!-- ── Left: heading + loop diagram ─────────────────── -->
        <div class="rm-left">

          <div class="rm-heading w95-inset">
            <p class="rm-heading-title">{{ title }}</p>
            <p class="rm-heading-sub">Desired state converges through continuous control.</p>
          </div>

          <div class="rm-diagram">

            <!--
              SVG uses preserveAspectRatio="none" so viewBox coords (0–100)
              map directly to container percentages — node `left`/`top` % values
              are derived from the same CX/CY/RX/RY constants, ensuring perfect alignment.
            -->
            <svg class="rm-svg" viewBox="0 0 100 100" preserveAspectRatio="none">
              <!-- Base ring (dim) -->
              <path
                class="ring-base"
                :d="`M ${CX - RX} ${CY} A ${RX} ${RY} 0 1 1 ${CX + RX} ${CY} A ${RX} ${RY} 0 1 1 ${CX - RX} ${CY}`"
              />
              <!-- Progress arc — studio technique: dasharray=CIRC, dashoffset=(CIRC - filled) -->
              <path
                class="ring-fill"
                :d="`M ${CX - RX} ${CY} A ${RX} ${RY} 0 1 1 ${CX + RX} ${CY} A ${RX} ${RY} 0 1 1 ${CX - RX} ${CY}`"
                :style="{
                  strokeDasharray: CIRC,
                  strokeDashoffset: CIRC - arcLen,
                  transition: 'stroke-dashoffset 0.45s ease',
                }"
              />
            </svg>

            <!-- Step nodes — positioned on the ellipse using computed % coordinates -->
            <div
              v-for="(step, i) in steps"
              :key="step.id"
              class="rm-node"
              :class="stateOf(i)"
              :style="{ left: `${nodePositions[i].x}%`, top: `${nodePositions[i].y}%` }"
            >
              <span class="rm-node-num">{{ step.id }}</span>
              <span class="rm-node-label">{{ step.label }}</span>
            </div>

          </div>
        </div>

        <!-- ── Right: info panels ───────────────────────────── -->
        <div class="rm-right">

          <!-- Progress panel -->
          <div class="rm-panel">
            <div class="rm-legend">Progress</div>
            <p class="rm-step-name">Step {{ current.id }}: {{ current.label }}</p>
            <div class="rm-bar-track">
              <div class="rm-bar-fill" :style="{ width: `${pct}%` }" />
            </div>
            <p class="rm-bar-caption">
              {{ props.activeStep < steps.length ? 'Advancing to next step' : 'Sequence complete' }}
            </p>
          </div>

          <!-- Step explainer -->
          <div class="rm-panel rm-explain">
            <div class="rm-legend">Step Explainer</div>
            <p class="rm-explain-text">{{ current.detail }}</p>
            <div class="rm-cmd phosphor">{{ current.cmd }}</div>
          </div>

          <!-- Event log — all steps, with done/active/pending states -->
          <div class="rm-panel rm-log">
            <div class="rm-legend">Event Log</div>
            <div
              v-for="(step, i) in steps"
              :key="`log-${step.id}`"
              class="rm-log-row"
              :class="stateOf(i)"
            >
              [{{ step.id }}] {{ step.label }}
            </div>
          </div>

        </div>
      </div>

      <!-- Status bar -->
      <div class="rm-status">
        <span>Mode: Step Playback</span>
        <span>F5 Reconcile</span>
        <span>F10 Exit</span>
      </div>

    </div>
  </div>
</template>

<style scoped>
/* ── Root ──────────────────────────────────────────────────── */
.rm-root {
  width: 100%;
  height: 100%;
  padding: 14px;
  display: flex;
}

.rm-bezel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: var(--w95-silver);
  min-height: 0;
}

/* ── Title bar ─────────────────────────────────────────────── */
.rm-titlebar {
  display: flex;
  align-items: center;
  gap: 6px;
  background: linear-gradient(90deg, #000080, #1084d0);
  color: #fff;
  font-family: var(--w95-font);
  font-weight: 700;
  font-size: 1rem;
  padding: 3px 4px;
  flex-shrink: 0;
}

.rm-titlebar-icon { font-size: 0.9rem; }
.rm-titlebar-text { flex: 1; }

.rm-titlebar-btns {
  display: flex;
  gap: 2px;
}

.rm-titlebar-btns button {
  background: var(--w95-silver);
  color: #000;
  border: none;
  box-shadow: var(--w95-raised);
  width: 20px;
  height: 18px;
  font-size: 0.7rem;
  cursor: pointer;
  font-family: var(--w95-font);
  line-height: 1;
}

/* ── Body grid ─────────────────────────────────────────────── */
.rm-body {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 290px;
  gap: 8px;
  padding: 8px;
  min-height: 0;
}

/* ── Left column ───────────────────────────────────────────── */
.rm-left {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-height: 0;
}

.rm-heading {
  flex-shrink: 0;
  padding: 8px 12px;
  background: #fff;
}

.rm-heading-title {
  margin: 0;
  font-family: var(--w95-font);
  font-size: 2rem;
  font-weight: 700;
  color: #000080;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  line-height: 1;
}

.rm-heading-sub {
  margin: 4px 0 0;
  font-family: var(--w95-font);
  font-size: 1rem;
  color: #333;
}

/* ── Diagram area ──────────────────────────────────────────── */
.rm-diagram {
  flex: 1;
  position: relative;
  background: #efefef;
  box-shadow: var(--w95-inset);
  min-height: 0;
}

/* SVG fills the container with no aspect-ratio constraint.
   This makes viewBox coords (0-100) equal to container percentage coords,
   so SVG paths and HTML node positions share the same coordinate space. */
.rm-svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.ring-base {
  fill: none;
  stroke: #a0a0a0;
  stroke-width: 0.9;
  opacity: 0.4;
}

.ring-fill {
  fill: none;
  stroke: #000080;
  stroke-width: 1.8;
  /* dasharray is set via :style binding (= CIRC constant) */
}

/* ── Step nodes ────────────────────────────────────────────── */
.rm-node {
  position: absolute;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  min-width: 96px;
  text-align: center;
  transition: opacity 0.3s ease;
}

.rm-node.pending { opacity: 0.28; }
.rm-node.done    { opacity: 0.6; }
.rm-node.active  { opacity: 1; }

.rm-node-num {
  display: block;
  font-family: var(--w95-mono-font);
  font-size: 0.78rem;
  font-weight: 700;
  background: #808080;
  color: #fff;
  padding: 1px 8px;
  letter-spacing: 0.06em;
}

.rm-node.done .rm-node-num {
  background: #555;
}

.rm-node.active .rm-node-num {
  background: #000080;
  animation: node-pulse 1.5s ease-in-out infinite;
}

.rm-node-label {
  display: block;
  font-family: var(--w95-font);
  font-size: 1rem;
  font-weight: 700;
  color: #222;
  background: rgba(220, 220, 220, 0.96);
  border: 1px solid #999;
  padding: 3px 9px;
  white-space: nowrap;
  line-height: 1.2;
  box-shadow: var(--w95-raised);
}

.rm-node.active .rm-node-label {
  color: #000080;
  background: #d6e4ff;
  border-color: #000080;
}

.rm-node.done .rm-node-label {
  color: #555;
  background: rgba(208, 208, 208, 0.75);
}

/* ── Right column ──────────────────────────────────────────── */
.rm-right {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-height: 0;
}

.rm-panel {
  background: var(--w95-silver);
  box-shadow: var(--w95-raised);
  padding: 6px 8px;
  flex-shrink: 0;
}

.rm-legend {
  font-family: var(--w95-font);
  font-size: 0.9rem;
  font-weight: 700;
  color: #000080;
  border-bottom: 1px solid var(--w95-gray);
  margin-bottom: 5px;
  padding-bottom: 3px;
}

/* Progress panel */
.rm-step-name {
  margin: 0 0 5px;
  font-family: var(--w95-font);
  font-size: 1.1rem;
  font-weight: 700;
  line-height: 1.2;
  color: #111;
}

.rm-bar-track {
  height: 18px;
  background: #fff;
  box-shadow: var(--w95-inset);
  margin-bottom: 5px;
}

.rm-bar-fill {
  height: 100%;
  background: repeating-linear-gradient(
    90deg,
    #000080 0,    #000080 10px,
    #1084d0 10px, #1084d0 16px
  );
  transition: width 0.4s ease;
}

.rm-bar-caption {
  margin: 0;
  font-family: var(--w95-mono-font);
  font-size: 0.88rem;
  color: #555;
}

/* Explainer panel */
.rm-explain {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-height: 0;
}

.rm-explain-text {
  margin: 0;
  font-family: var(--w95-font);
  font-size: 1.05rem;
  line-height: 1.4;
  flex: 1;
  color: #111;
}

.rm-cmd {
  font-family: var(--w95-mono-font);
  font-size: 0.9rem;
  background: #111;
  padding: 7px 9px;
  white-space: pre-wrap;
  word-break: break-all;
  /* .phosphor class from global style.css adds green glow */
}

/* Event log panel */
.rm-log {
  flex-shrink: 0;
}

.rm-log-row {
  font-family: var(--w95-mono-font);
  font-size: 0.95rem;
  padding: 2px 4px;
  line-height: 1.35;
  transition: background 0.2s ease, color 0.2s ease;
  color: #bbb;
}

.rm-log-row.done    { color: #555; }
.rm-log-row.active  { color: #000080; font-weight: 700; background: #d6e4ff; }
.rm-log-row.pending { color: #bbb; }

/* ── Status bar ────────────────────────────────────────────── */
.rm-status {
  display: flex;
  gap: 24px;
  padding: 3px 10px;
  border-top: 1px solid var(--w95-gray);
  font-family: var(--w95-mono-font);
  font-size: 0.82rem;
  color: #333;
  flex-shrink: 0;
}

/* ── Animations ────────────────────────────────────────────── */
@keyframes node-pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.6; }
}
</style>
