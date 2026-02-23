<script setup lang="ts">
export interface Process {
  name: string
  pid?: number | string
  cpu?: number
  memory?: string
  status?: 'Running' | 'Ready' | 'Terminating' | 'Pending' | 'CrashLoopBackOff' | 'Completed' | 'Error'
  namespace?: string
  node?: string
}

const props = withDefaults(defineProps<{
  title?: string
  processes?: Process[]
  selectedPid?: number | string
  showNamespace?: boolean
  showNode?: boolean
  statusText?: string
  tab?: 'Processes' | 'Pods' | 'Performance'
}>(), {
  title: 'Windows Task Manager',
  processes: () => [],
  showNamespace: false,
  showNode: false,
  statusText: '',
  tab: 'Processes',
})

const statusColor: Record<string, string> = {
  Running:           '#000080',
  Ready:             '#006400',
  Terminating:       '#8b4513',
  Pending:           '#806000',
  CrashLoopBackOff:  '#cc0000',
  Completed:         '#006400',
  Error:             '#cc0000',
}

const cpuBar = (cpu?: number) => {
  if (cpu == null) return ''
  const filled = Math.round((cpu / 100) * 10)
  return '█'.repeat(filled) + '░'.repeat(10 - filled)
}
</script>

<template>
  <Win95Window :title="title" icon="🖥" :status-text="statusText || `Processes: ${processes.length}`">
    <!-- Tabs -->
    <template #menu>
      <div class="tm-tabs">
        <div
          v-for="t in ['Applications', tab, 'Performance', 'Networking']"
          :key="t"
          class="tm-tab"
          :class="{ active: t === tab }"
        >{{ t }}</div>
      </div>
    </template>

    <!-- Process table -->
    <div class="tm-body" :class="{ 'no-pad': true }">
      <table class="tm-table">
        <thead>
          <tr>
            <th class="col-name sort-active">Name ▼</th>
            <th v-if="showNamespace" class="col-ns">Namespace</th>
            <th class="col-pid">PID</th>
            <th class="col-cpu">CPU</th>
            <th class="col-mem">Mem</th>
            <th class="col-status">Status</th>
            <th v-if="showNode" class="col-node">Node</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="proc in processes"
            :key="proc.pid ?? proc.name"
            class="tm-row"
            :class="{
              selected: proc.pid === selectedPid,
              crashing: proc.status === 'CrashLoopBackOff',
              terminating: proc.status === 'Terminating',
            }"
          >
            <td class="col-name">{{ proc.name }}</td>
            <td v-if="showNamespace" class="col-ns">{{ proc.namespace ?? '—' }}</td>
            <td class="col-pid">{{ proc.pid ?? '—' }}</td>
            <td class="col-cpu">
              <span class="cpu-bar">{{ cpuBar(proc.cpu) }}</span>
            </td>
            <td class="col-mem">{{ proc.memory ?? '—' }}</td>
            <td class="col-status">
              <span
                class="status-badge"
                :style="{ color: statusColor[proc.status ?? 'Running'] ?? '#000' }"
              >
                {{ proc.status ?? 'Running' }}
              </span>
            </td>
            <td v-if="showNode" class="col-node">{{ proc.node ?? '—' }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Bottom buttons -->
    <div class="tm-footer">
      <Win95Button label="End Process" />
      <Win95Button label="End Task" :disabled="true" />
    </div>
  </Win95Window>
</template>

<style scoped>
/* ── Tabs ────────────────────────────────────────────────── */
.tm-tabs {
  display: flex;
  gap: 2px;
  padding: 2px 4px 0;
}

.tm-tab {
  padding: 2px 10px;
  font-family: var(--w95-font);
  font-size: 12px;
  color: var(--w95-black);
  background: var(--w95-silver);
  border: 1px solid var(--w95-gray);
  border-bottom: none;
  cursor: pointer;
  position: relative;
  top: 1px;
}

.tm-tab.active {
  background: var(--w95-silver);
  border-color: var(--w95-black);
  font-weight: 700;
  padding-bottom: 3px;
  z-index: 1;
}

/* ── Table ───────────────────────────────────────────────── */
.tm-body {
  padding: 0;
}

.tm-table {
  width: 100%;
  border-collapse: collapse;
  font-family: var(--w95-font);
  font-size: 12px;
  table-layout: fixed;
}

.tm-table thead tr {
  background: var(--w95-silver);
}

.tm-table th {
  text-align: left;
  padding: 2px 6px;
  font-weight: 700;
  font-size: 12px;
  border-right: 1px solid var(--w95-gray);
  border-bottom: 2px solid var(--w95-gray);
  box-shadow: var(--w95-raised);
  white-space: nowrap;
  overflow: hidden;
  user-select: none;
  cursor: pointer;
}

.tm-table th.sort-active {
  background: var(--w95-light);
}

.tm-table td {
  padding: 2px 6px;
  border-bottom: 1px solid transparent;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ── Row states ──────────────────────────────────────────── */
.tm-row:hover {
  background: rgba(0,0,128,0.08);
}

.tm-row.selected {
  background: var(--w95-select-bg);
  color: var(--w95-select-text);
}

.tm-row.selected .status-badge {
  color: var(--w95-white) !important;
}

.tm-row.crashing {
  background: rgba(204,0,0,0.08);
}

.tm-row.terminating {
  opacity: 0.6;
  font-style: italic;
}

/* ── Column widths ───────────────────────────────────────── */
.col-name   { width: 34%; }
.col-ns     { width: 16%; }
.col-pid    { width: 8%;  text-align: right; }
.col-cpu    { width: 16%; font-family: var(--w95-mono-font); font-size: 11px; }
.col-mem    { width: 10%; text-align: right; }
.col-status { width: 14%; }
.col-node   { width: 14%; }

.cpu-bar {
  font-family: var(--w95-mono-font);
  font-size: 10px;
  letter-spacing: -1px;
  color: var(--w95-navy-dark);
}

.status-badge {
  font-weight: 700;
  font-size: 11px;
}

/* ── Footer ──────────────────────────────────────────────── */
.tm-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 6px 8px;
  border-top: 1px solid var(--w95-gray);
  background: var(--w95-silver);
}
</style>
