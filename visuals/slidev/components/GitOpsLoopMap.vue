<script setup lang="ts">
// Static diagram — GitOps desired-state control loop
</script>

<template>
  <div class="gitops-map">

    <!-- ── Top row: Dev → Git → Argo ─────────────────────── -->
    <div class="map-row row-top">

      <div class="node node-dev">
        <div class="node-kind">Developer</div>
        <div class="node-name">git push origin main</div>
        <div class="node-meta">trigger</div>
      </div>

      <div class="arrow arrow-h">
        <div class="arrow-line" />
        <div class="arrow-head">▶</div>
      </div>

      <div class="node node-git">
        <div class="node-kind">Git Repository</div>
        <div class="node-name">main branch</div>
        <div class="node-meta">source of truth</div>
      </div>

      <div class="arrow arrow-h">
        <div class="arrow-line" />
        <div class="arrow-head">▶</div>
      </div>

      <div class="node node-argo">
        <div class="node-kind">ArgoCD</div>
        <div class="node-name">watches repo</div>
        <div class="node-meta">detects drift</div>
      </div>

    </div>

    <!-- ── Vertical connectors column (left=health back to dev, right=argo down to apply) -->
    <div class="map-connector-row">
      <div class="arrow-v arrow-v-left">
        <div class="arrow-head-v">▲</div>
        <div class="arrow-line-v" />
      </div>
      <div class="connector-spacer" />
      <div class="arrow-v arrow-v-right">
        <div class="arrow-line-v" />
        <div class="arrow-head-v">▼</div>
      </div>
    </div>

    <!-- ── Bottom row: Health ← Live ← Apply ────────────── -->
    <div class="map-row row-bottom">

      <div class="node node-health">
        <div class="node-kind">Healthy + Synced</div>
        <div class="node-name">Drift = 0</div>
        <div class="node-meta">self-healing complete</div>
      </div>

      <div class="arrow arrow-h arrow-left">
        <div class="arrow-head">◀</div>
        <div class="arrow-line" />
      </div>

      <div class="node node-live">
        <div class="node-kind">Live Cluster State</div>
        <div class="node-name">current resources</div>
        <div class="node-meta">continuous watch</div>
      </div>

      <div class="arrow arrow-h arrow-left">
        <div class="arrow-head">◀</div>
        <div class="arrow-line" />
      </div>

      <div class="node node-apply">
        <div class="node-kind">Apply Manifests</div>
        <div class="node-name">kustomize build | apply</div>
        <div class="node-meta">reconcile loop</div>
      </div>

    </div>

  </div>
</template>

<style scoped>
/* ── Container ───────────────────────────────────────────── */
.gitops-map {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: calc(100% - 44px);
  min-height: 280px;
  gap: 0;
}

/* ── Rows ────────────────────────────────────────────────── */
.map-row {
  display: flex;
  align-items: stretch;
  flex: 1;
}

/* ── Connector row ───────────────────────────────────────── */
.map-connector-row {
  display: flex;
  height: 32px;
  flex-shrink: 0;
  align-items: stretch;
}

.connector-spacer {
  flex: 1;
}

/* ── Nodes ───────────────────────────────────────────────── */
.node {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  gap: 4px;
  box-shadow: var(--w95-raised);
  overflow: hidden;
}

.node-kind {
  width: 100%;
  background: var(--w95-navy-dark);
  color: var(--w95-white);
  font-family: var(--w95-font);
  font-size: 0.85rem;
  font-weight: 700;
  padding: 6px 8px;
  text-align: center;
  letter-spacing: 0.03em;
  flex-shrink: 0;
}

.node-name {
  font-family: var(--w95-font);
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--w95-black);
  padding: 4px 8px;
  line-height: 1.3;
}

.node-meta {
  font-family: var(--w95-mono-font);
  font-size: 0.8rem;
  color: var(--w95-gray);
  padding: 0 8px 6px;
}

/* per-node accent bars */
.node-dev    .node-kind { background: #2471a3; }
.node-git    .node-kind { background: #1a5276; }
.node-argo   .node-kind { background: #117a65; }
.node-apply  .node-kind { background: #117a65; }
.node-live   .node-kind { background: #1e6b3a; }
.node-health .node-kind { background: #1e8449; }

/* ── Horizontal arrows ───────────────────────────────────── */
.arrow-h {
  flex: 0 0 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
}

.arrow-line {
  flex: 1;
  height: 2px;
  background: var(--w95-gray);
}

.arrow-head {
  font-size: 1rem;
  color: var(--w95-dark);
  line-height: 1;
  flex-shrink: 0;
}

.arrow-left {
  flex-direction: row-reverse;
}

/* ── Vertical arrows ─────────────────────────────────────── */
.arrow-v {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 44px;
  flex-shrink: 0;
}

/* left column: arrow goes UP (health signal back to start) */
.arrow-v-left {
  /* occupies same width as one node in the row */
  flex: 0 0 calc((100% - 88px) / 3);   /* roughly 1 node width */
}

/* right column: arrow goes DOWN (argo → apply) */
.arrow-v-right {
  flex: 0 0 calc((100% - 88px) / 3);   /* roughly 1 node width */
}

.arrow-line-v {
  width: 2px;
  flex: 1;
  background: var(--w95-gray);
}

.arrow-head-v {
  font-size: 1rem;
  color: var(--w95-dark);
  line-height: 1;
  flex-shrink: 0;
}
</style>
