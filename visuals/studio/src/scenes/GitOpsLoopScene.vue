<script setup>
const props = defineProps({
  title: { type: String, default: 'GitOps Reconcile Loop' },
  subtitle: { type: String, default: 'Commit -> Detect -> Diff -> Apply -> Observe' },
  progress: { type: Number, default: 1 },
})

const steps = [
  {
    key: 'commit',
    label: 'Commit to Git',
    command: 'git commit -m "update" && git push',
    explain: 'You commit code and push desired state into the Git repository.',
  },
  {
    key: 'detect',
    label: 'Webhook / Poll',
    command: 'source-controller: revision detected',
    explain: 'Webhook or polling checks for new commits in the repo.',
  },
  {
    key: 'diff',
    label: 'Compute Diff',
    command: 'kustomize-controller: diff desired vs live',
    explain: 'Controller compares desired state with live cluster resources.',
  },
  {
    key: 'apply',
    label: 'Apply Changes',
    command: 'kubectl apply --server-side -f manifests/',
    explain: 'Controller applies the new manifests to converge state.',
  },
  {
    key: 'verify',
    label: 'Verify Health',
    command: 'health checks: passing, drift: none',
    explain: 'Health checks validate workloads and monitor drift continuously.',
  },
  {
    key: 'loop',
    label: 'Loop Continues',
    command: 'status: synced @ revision 9d4f2c7',
    explain: 'Status updates are visible to operators and the loop repeats.',
  },
]

const loopCenter = { x: 46, y: 47 }
const loopRadius = { x: 31, y: 20 }
const stepAngles = [180, 240, 300, 0, 60, 120]

const loopPoint = (index) => {
  const degrees = stepAngles[index % stepAngles.length]
  const radians = (degrees * Math.PI) / 180
  return {
    x: loopCenter.x + Math.cos(radians) * loopRadius.x,
    y: loopCenter.y + Math.sin(radians) * loopRadius.y,
  }
}

const nodePlacement = (index) => {
  const point = loopPoint(index)
  return {
    left: `${point.x}%`,
    top: `${point.y}%`,
  }
}

const TRANSITION_PORTION = 0.24
const clamp = (value) => Math.max(0, Math.min(1, value))

const currentStepIndex = () => {
  const scaled = clamp(props.progress) * steps.length
  return Math.min(steps.length - 1, Math.floor(scaled))
}

const localStepProgress = () => {
  const scaled = clamp(props.progress) * steps.length
  return clamp(scaled - Math.floor(scaled))
}

const pauseActive = () => localStepProgress() >= TRANSITION_PORTION

const transitionProgress = () => clamp(localStepProgress() / TRANSITION_PORTION)

const pathProgress = () => {
  const base = currentStepIndex() / steps.length
  const extra = transitionProgress() / steps.length
  return clamp(base + extra)
}

const segmentCount = 14
const filledSegments = () => Math.round(pathProgress() * segmentCount)
const loopPathLength = 162

const nodeStrength = (index) => {
  const active = currentStepIndex()
  if (index < active) return 0.74
  if (index > active) return 0.45
  if (pauseActive()) return 1
  return 0.58 + transitionProgress() * 0.42
}
</script>

<template>
  <section class="scene">
    <article class="window shell">
      <div class="title-bar">
        <div class="title-bar-text">GitOps Monitor.exe</div>
        <div class="title-bar-controls">
          <button aria-label="Minimize" />
          <button aria-label="Maximize" />
          <button aria-label="Close" />
        </div>
      </div>

      <div class="window-body body-grid">
        <section class="left-pane">
          <div class="heading-line">
            <h1 class="title">{{ title }}</h1>
            <p class="subtitle">{{ subtitle }}</p>
          </div>

          <div class="diagram-surface">
            <svg class="loop-wire" viewBox="0 0 100 100" preserveAspectRatio="none">
              <path
                class="base-wire"
                d="M15 47 A31 20 0 1 1 77 47 A31 20 0 1 1 15 47"
              />
              <path
                class="active-wire"
                :style="{ strokeDashoffset: `${loopPathLength - pathProgress() * loopPathLength}` }"
                d="M15 47 A31 20 0 1 1 77 47 A31 20 0 1 1 15 47"
              />
            </svg>

            <article
              v-for="(step, index) in steps"
              :key="step.key"
              class="node"
              :style="{
                ...nodePlacement(index),
                opacity: 0.48 + nodeStrength(index) * 0.52,
                transform: 'translate(-50%, -50%)',
              }"
            >
              <p class="node-index">{{ String(index + 1).padStart(2, '0') }}</p>
              <p class="node-label">{{ step.label }}</p>
            </article>
          </div>
        </section>

        <aside class="right-pane">
          <fieldset>
            <legend>Progress</legend>
            <p class="current-step">Step {{ String(currentStepIndex() + 1).padStart(2, '0') }}: {{ steps[currentStepIndex()].label }}</p>
            <div class="progress-98">
              <div class="progress-98-fill" :style="{ width: `${Math.round((filledSegments() / segmentCount) * 100)}%` }" />
            </div>
            <p class="meter-caption">{{ pauseActive() ? 'Paused on explanation' : 'Advancing to next step' }}</p>
          </fieldset>

          <fieldset class="popup-box">
            <legend>Step Explainer</legend>
            <p class="popup-text">{{ steps[currentStepIndex()].explain }}</p>
            <div class="command-line">{{ steps[currentStepIndex()].command }}</div>
          </fieldset>

          <fieldset>
            <legend>Event Log</legend>
            <ul class="event-list">
              <li
                v-for="(step, index) in steps"
                :key="step.key"
                :class="{ active: index === currentStepIndex(), done: index < currentStepIndex() }"
              >
                [{{ String(index + 1).padStart(2, '0') }}] {{ step.label }}
              </li>
            </ul>
          </fieldset>
        </aside>
      </div>

      <section class="status-bar">
        <p class="status-bar-field">Mode: Step Playback</p>
        <p class="status-bar-field">F5 Reconcile</p>
        <p class="status-bar-field">F10 Exit</p>
      </section>
    </article>
  </section>
</template>

<style scoped>
.scene {
  width: 100%;
  height: 100%;
  padding: 28px;
}

.shell {
  height: 100%;
  display: grid;
  grid-template-rows: auto 1fr auto;
}

.body-grid {
  display: grid;
  grid-template-columns: 1.58fr 1fr;
  gap: 12px;
  min-height: 0;
}

.left-pane {
  display: grid;
  grid-template-rows: auto 1fr;
  gap: 10px;
  min-height: 0;
}

.heading-line {
  border: 2px solid;
  border-color: #808080 #ffffff #ffffff #808080;
  background: #ffffff;
  padding: 10px;
}

.title {
  margin: 0;
  font-size: 2.9rem;
  color: #000080;
}

.subtitle {
  margin: 4px 0 0;
  color: #222;
  font-size: 1.32rem;
}

.diagram-surface {
  position: relative;
  min-height: 0;
  border: 2px solid;
  border-color: #808080 #ffffff #ffffff #808080;
  background: #f3f3f3;
}

.loop-wire {
  position: absolute;
  inset: 0;
}

.base-wire {
  fill: none;
  stroke: #8a8a8a;
  stroke-width: 1.5;
}

.active-wire {
  fill: none;
  stroke: #000080;
  stroke-width: 2.2;
  stroke-dasharray: 162;
}

.node {
  position: absolute;
  width: 122px;
  min-height: 40px;
  transform: translate(-50%, -50%);
  display: grid;
  justify-items: center;
  align-content: center;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  background: rgba(206, 206, 206, 0.96);
  padding: 4px 6px;
  text-align: center;
}

.node-index,
.node-label {
  margin: 0;
}

.node-index {
  font-family: var(--mono-font);
  font-size: 0.72rem;
  line-height: 1;
  color: #000080;
}

.node-label {
  font-size: 0.8rem;
  line-height: 1.05;
  white-space: nowrap;
}

.right-pane {
  display: grid;
  gap: 10px;
  grid-template-rows: 0.85fr 1fr 1.15fr;
}

fieldset {
  margin: 0;
  min-inline-size: 0;
  border: 2px groove #dfdfdf;
  background: #efefef;
  padding: 12px;
}

legend {
  padding: 0 6px;
  color: #000080;
  font-weight: 700;
  font-size: 1.08rem;
}

.current-step,
.meter-caption,
.popup-text {
  margin: 0;
}

.current-step {
  margin-bottom: 6px;
  font-weight: 700;
  font-size: 1.48rem;
  line-height: 1.15;
}

.meter-caption {
  margin-top: 6px;
  font-size: 1.24rem;
}

.popup-text {
  font-size: 1.42rem;
  line-height: 1.25;
}

.popup-box {
  display: grid;
  gap: 8px;
}

.command-line {
  border: 2px solid;
  border-color: #808080 #ffffff #ffffff #808080;
  background: #000;
  color: #49ff00;
  font-family: var(--mono-font);
  font-size: 2rem;
  line-height: 1.05;
  padding: 8px 10px;
}

.event-list {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 6px;
  height: 100%;
  grid-auto-rows: minmax(36px, 1fr);
  align-content: stretch;
}

.event-list li {
  font-family: var(--mono-font);
  font-size: 1.52rem;
  color: #333;
  display: flex;
  align-items: center;
  padding: 0 6px;
}

.event-list li.done {
  color: #5b5b5b;
}

.event-list li.active {
  color: #000080;
  font-weight: 700;
  background: #d6e4ff;
}
</style>
