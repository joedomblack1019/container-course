<script setup>
const props = defineProps({
  title: { type: String, default: 'etcd Replication + Quorum' },
  subtitle: { type: String, default: 'Writes commit only after majority acknowledgment.' },
  progress: { type: Number, default: 1 },
  profile: { type: String, default: 'industrial-control' },
})

const members = [
  { id: 'etcd-a', role: 'leader', x: 22, y: 58 },
  { id: 'etcd-b', role: 'follower', x: 50, y: 28 },
  { id: 'etcd-c', role: 'follower', x: 78, y: 58 },
]

const phases = [
  {
    label: 'Client Write',
    explain: 'API server submits write to etcd leader.',
    cmd: 'etcdctl put /registry/deployments/web spec-v7',
  },
  {
    label: 'Leader Append',
    explain: 'Leader appends entry to its local WAL.',
    cmd: 'leader append index=490 term=7',
  },
  {
    label: 'Replicate Follower 1',
    explain: 'Leader sends append entries to follower B.',
    cmd: 'appendEntries -> etcd-b (ack)',
  },
  {
    label: 'Replicate Follower 2',
    explain: 'Leader sends append entries to follower C.',
    cmd: 'appendEntries -> etcd-c (ack)',
  },
  {
    label: 'Quorum Commit',
    explain: 'Majority has acknowledged. Entry is committed.',
    cmd: 'commit index=490 quorum=2/3',
  },
  {
    label: 'Apply + Respond',
    explain: 'State machine applies entry and responds success.',
    cmd: 'apply index=490 && return 200',
  },
]

const clamp = (value, min = 0, max = 1) => Math.max(min, Math.min(max, value))

const phaseIndex = () => {
  const p = clamp(props.progress)
  return Math.min(phases.length - 1, Math.floor(p * phases.length))
}

const ackCount = () => {
  if (phaseIndex() < 2) return 1
  if (phaseIndex() < 3) return 2
  return 3
}

const committed = () => phaseIndex() >= 4
</script>

<template>
  <section class="scene" :class="{ 'is-win98': props.profile === 'win98-classic' }">
    <div class="panel shell">
      <header class="frame-header">
        <span class="prompt">C:\ETCD\CLUSTER></span>
        <span class="header-title">REPLICATION / QUORUM VIEW</span>
        <span class="clock">RAFT</span>
      </header>

      <div class="map body-grid">
        <div class="main-col">
          <div class="heading">
            <p class="eyebrow">Control Plane Internals</p>
            <h1 class="title">{{ title }}</h1>
            <p class="subtitle">{{ subtitle }}</p>
          </div>

        <svg class="wires" viewBox="0 0 100 100" preserveAspectRatio="none">
          <line x1="22" y1="58" x2="50" y2="28" />
          <line x1="50" y1="28" x2="78" y2="58" />
          <line x1="22" y1="58" x2="78" y2="58" />
          <line class="replicate" x1="22" y1="58" x2="50" y2="28" :style="{ opacity: phaseIndex() >= 2 ? 1 : 0.2 }" />
          <line class="replicate" x1="22" y1="58" x2="78" y2="58" :style="{ opacity: phaseIndex() >= 3 ? 1 : 0.2 }" />
        </svg>

        <article
          v-for="member in members"
          :key="member.id"
          class="member panel"
          :style="{
            left: `${member.x}%`,
            top: `${member.y}%`,
            borderColor: member.role === 'leader' ? 'var(--accent)' : 'var(--line)',
          }"
        >
          <p class="member-name">{{ member.id }}</p>
          <p class="member-role">{{ member.role }}</p>
          <p class="member-log">log idx: {{ 482 + Math.round(progress * 8) }} term: 7</p>
        </article>
        </div>

        <aside class="side-col">
          <div class="status panel">
            <span class="chip">acknowledged {{ ackCount() }}/3</span>
            <h2 class="status-title">
              <span v-if="ackCount() >= 2">Quorum reached</span>
              <span v-else>Waiting for quorum</span>
            </h2>
            <p class="status-note">With 3 members, quorum is 2. If one fails, writes can continue.</p>
            <div class="status-meter">
              <div class="status-fill" :style="{ width: `${Math.round(progress * 100)}%` }" />
            </div>
          </div>

          <div class="panel explain">
            <p class="side-title">CURRENT PHASE</p>
            <p class="phase-line">[{{ String(phaseIndex() + 1).padStart(2, '0') }}] {{ phases[phaseIndex()].label }}</p>
            <p class="phase-note">{{ phases[phaseIndex()].explain }}</p>
            <pre>{{ phases[phaseIndex()].cmd }}</pre>
          </div>

          <div class="panel explain">
            <p class="side-title">CONSISTENCY</p>
            <p class="phase-line" :class="{ good: committed() }">{{ committed() ? 'COMMITTED' : 'PENDING COMMIT' }}</p>
            <p class="phase-note">Linearizable write completes only after quorum acknowledgment.</p>
          </div>
        </aside>
      </div>

      <footer class="frame-footer">
        <span>F3 Replicate</span>
        <span>F6 Quorum</span>
        <span>F10 Exit</span>
      </footer>
    </div>
  </section>
</template>

<style scoped>
.scene {
  width: 100%;
  height: 100%;
  padding: 34px;
}

.shell {
  height: 100%;
  display: grid;
  grid-template-rows: 42px 1fr 34px;
  border-color: rgba(120, 231, 77, 0.42);
  background: rgba(6, 12, 8, 0.9);
}

.frame-header {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 14px;
  padding: 0 14px;
  border-bottom: 1px solid rgba(120, 231, 77, 0.34);
  background: linear-gradient(180deg, rgba(124, 235, 82, 0.13), rgba(124, 235, 82, 0.03));
  font-family: var(--mono-font);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.82rem;
}

.prompt {
  color: var(--accent-2);
}

.header-title {
  color: #d8ffc7;
  text-align: center;
}

.clock {
  color: var(--accent);
}

.title {
  font-size: 2.7rem;
  line-height: 0.97;
  max-width: 760px;
  color: #e9ffd7;
}

.subtitle {
  margin: 6px 0 0;
  color: #9fe68d;
  font-size: 1rem;
}

.map {
  position: relative;
  min-height: 0;
}

.body-grid {
  display: grid;
  grid-template-columns: 1.55fr 0.85fr;
  gap: 14px;
  padding: 14px;
}

.main-col {
  position: relative;
  min-height: 0;
}

.heading {
  display: grid;
  gap: 4px;
  margin-bottom: 6px;
}

.wires {
  position: absolute;
  inset: 20% 4% 8% 2%;
}

.wires line {
  stroke: rgba(120, 231, 77, 0.25);
  stroke-width: 1.3;
}

.wires .replicate {
  stroke: var(--accent-2);
  stroke-width: 2.6;
  transition: opacity 220ms ease;
}

.member {
  position: absolute;
  transform: translate(-50%, -50%);
  width: 236px;
  padding: 14px 16px;
  display: grid;
  gap: 6px;
  background: rgba(7, 17, 10, 0.9);
}

.member-name,
.member-role,
.member-log {
  margin: 0;
}

.member-name {
  font-size: 1.35rem;
  font-weight: 700;
}

.member-role {
  text-transform: uppercase;
  font-family: var(--mono-font);
  color: #ffdca3;
  font-size: 0.8rem;
  letter-spacing: 0.08em;
}

.member-log {
  color: #9fd889;
  font-family: var(--mono-font);
  font-size: 0.84rem;
}

.side-col {
  display: grid;
  gap: 10px;
  grid-template-rows: auto auto 1fr;
}

.status {
  padding: 14px;
  display: grid;
  gap: 8px;
  border-color: rgba(120, 231, 77, 0.34);
  background: rgba(8, 17, 10, 0.84);
}

.status-title {
  margin: 0;
  font-size: 1.65rem;
  font-family: var(--display-font);
  letter-spacing: 0.04em;
}

.status-note {
  margin: 0;
  color: #9fd889;
  line-height: 1.4;
}

.status-meter {
  height: 10px;
  border: 1px solid var(--line);
  background: rgba(0, 0, 0, 0.35);
}

.status-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent), var(--accent-2));
}

.explain {
  padding: 14px;
  border-color: rgba(120, 231, 77, 0.3);
  background: rgba(8, 16, 9, 0.84);
}

.side-title {
  margin: 0 0 7px;
  color: var(--accent);
  font-family: var(--mono-font);
  text-transform: uppercase;
  letter-spacing: 0.09em;
  font-size: 0.82rem;
}

.phase-line {
  margin: 0 0 6px;
  font-size: 1.05rem;
  color: #e8ffd8;
  font-weight: 700;
}

.phase-line.good {
  color: #ffd89c;
}

.phase-note {
  margin: 0 0 8px;
  color: #9fd889;
  line-height: 1.4;
}

.explain pre {
  margin: 0;
  border: 1px solid rgba(120, 231, 77, 0.28);
  background: rgba(4, 11, 6, 0.85);
  padding: 8px 10px;
  color: #ffdca3;
  font-family: var(--mono-font);
  white-space: pre-wrap;
}

.frame-footer {
  border-top: 1px solid rgba(120, 231, 77, 0.35);
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 0 12px;
  font-family: var(--mono-font);
  font-size: 0.79rem;
  color: #9fe68d;
  background: rgba(124, 235, 82, 0.05);
}

.scene.is-win98 .shell {
  border: 2px solid;
  border-color: #dfdfdf #404040 #404040 #dfdfdf;
  background: #c0c0c0;
}

.scene.is-win98 .frame-header {
  border-bottom: 1px solid #808080;
  background: #c0c0c0;
  color: #111;
}

.scene.is-win98 .prompt,
.scene.is-win98 .header-title,
.scene.is-win98 .clock {
  color: #000080;
}

.scene.is-win98 .title {
  color: #000080;
}

.scene.is-win98 .subtitle {
  color: #1f1f1f;
}

.scene.is-win98 .wires line {
  stroke: #6f6f6f;
  stroke-width: 1.5;
}

.scene.is-win98 .wires .replicate {
  stroke: #1084d0;
}

.scene.is-win98 .member {
  background: #e6e6e6;
}

.scene.is-win98 .member-role {
  color: #5f4200;
}

.scene.is-win98 .member-log {
  color: #222;
}

.scene.is-win98 .status,
.scene.is-win98 .explain {
  background: #e9e9e9;
  border: 1px solid #8c8c8c;
}

.scene.is-win98 .status-title,
.scene.is-win98 .side-title {
  color: #000080;
}

.scene.is-win98 .status-note,
.scene.is-win98 .phase-note,
.scene.is-win98 .phase-line,
.scene.is-win98 .phase-line.good {
  color: #1d1d1d;
}

.scene.is-win98 .status-meter {
  border-color: #808080 #ffffff #ffffff #808080;
  background: #ffffff;
}

.scene.is-win98 .status-fill {
  background: #1084d0;
}

.scene.is-win98 .explain pre {
  border-color: #808080 #ffffff #ffffff #808080;
  background: #111;
  color: #f8f8f8;
}

.scene.is-win98 .frame-footer {
  border-top: 1px solid #808080;
  color: #111;
  background: #c0c0c0;
}
</style>
