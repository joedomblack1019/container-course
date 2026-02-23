<script setup lang="ts">
// No props — this is a static diagram showing full RBAC chain
</script>

<template>
  <div class="rbac-map">

    <!-- ── Row 1: Subject chain (left to right) ─────────────── -->
    <div class="map-row row-1">

      <div class="node node-subject">
        <div class="node-kind">ServiceAccount</div>
        <div class="node-name">trainee</div>
        <div class="node-meta">ns: rbac-lab</div>
      </div>

      <div class="arrow arrow-h">
        <div class="arrow-line" />
        <div class="arrow-head">▶</div>
      </div>

      <div class="node node-binding">
        <div class="node-kind">RoleBinding</div>
        <div class="node-name">trainee-pod-reader</div>
        <div class="node-meta">ns: rbac-lab</div>
      </div>

      <div class="arrow arrow-h">
        <div class="arrow-line" />
        <div class="arrow-head">▶</div>
      </div>

      <div class="node node-role">
        <div class="node-kind">Role</div>
        <div class="node-name">pod-reader</div>
        <div class="node-meta">ns: rbac-lab</div>
      </div>

    </div>

    <!-- ── Vertical connector: Role → Rules ─────────────────── -->
    <div class="map-connector-row">
      <div class="connector-spacer" />
      <div class="arrow-v">
        <div class="arrow-line-v" />
        <div class="arrow-head-v">▼</div>
      </div>
    </div>

    <!-- ── Row 2: Rules ← Authorizer ← Decision ─────────────── -->
    <div class="map-row row-2">

      <div class="node node-decision">
        <div class="node-kind">Decision</div>
        <div class="node-name">
          <span class="allow">✓ Allow</span>
          <span class="sep"> / </span>
          <span class="deny">✗ Deny</span>
        </div>
        <div class="node-meta">kubectl auth can-i</div>
      </div>

      <div class="arrow arrow-h arrow-left">
        <div class="arrow-head">◀</div>
        <div class="arrow-line" />
      </div>

      <div class="node node-authorizer">
        <div class="node-kind">Kubernetes Authorizer</div>
        <div class="node-name">RBAC engine</div>
        <div class="node-meta">kube-apiserver</div>
      </div>

      <div class="arrow arrow-h arrow-left">
        <div class="arrow-head">◀</div>
        <div class="arrow-line" />
      </div>

      <div class="node node-rules">
        <div class="node-kind">Role Rules</div>
        <div class="node-name">get, list, watch</div>
        <div class="node-meta">resources: pods</div>
      </div>

    </div>

  </div>
</template>

<style scoped>
/* ── Container ───────────────────────────────────────────── */
.rbac-map {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: calc(100% - 44px);   /* fill below h2 heading */
  min-height: 280px;
  gap: 0;
}

/* ── Rows ────────────────────────────────────────────────── */
.map-row {
  display: flex;
  align-items: stretch;
  flex: 1;
  gap: 0;
}

/* Row 2 is right-aligned — mirrors row 1's 3 nodes in reverse */
.row-2 {
  flex-direction: row;
}

/* ── Connector row (vertical arrow between rows) ─────────── */
.map-connector-row {
  display: flex;
  height: 32px;
  flex-shrink: 0;
  align-items: center;
}

.connector-spacer {
  /* width = 2 nodes + 2 arrows in row 1, to align with the right node */
  flex: 4;          /* 2 nodes (flex:1 each) + 2 arrows (flex:0.3 each) = ~2.6, approx with 4 */
  min-width: 0;
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
  font-size: 0.75rem;
  font-weight: 700;
  padding: 4px 8px;
  text-align: center;
  letter-spacing: 0.03em;
  flex-shrink: 0;
}

.node-name {
  font-family: var(--w95-font);
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--w95-black);
  padding: 2px 8px;
  line-height: 1.3;
}

.node-meta {
  font-family: var(--w95-mono-font);
  font-size: 0.72rem;
  color: var(--w95-gray);
  padding: 0 8px 4px;
}

/* per-node accent colors on the kind bar */
.node-subject   .node-kind { background: #1a5276; }
.node-binding   .node-kind { background: #1d6a96; }
.node-role      .node-kind { background: #2471a3; }
.node-rules     .node-kind { background: #2471a3; }
.node-authorizer .node-kind { background: #117a65; }
.node-decision  .node-kind { background: #1e8449; }

/* decision allow/deny coloring */
.allow { color: #1e8449; font-weight: 700; }
.deny  { color: #c0392b; font-weight: 700; }
.sep   { color: var(--w95-gray); }

/* ── Horizontal arrows ───────────────────────────────────── */
.arrow-h {
  flex: 0 0 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
  color: var(--w95-dark);
  font-size: 0.9rem;
}

.arrow-line {
  flex: 1;
  height: 2px;
  background: var(--w95-gray);
}

.arrow-head {
  font-size: 0.85rem;
  color: var(--w95-dark);
  flex-shrink: 0;
  line-height: 1;
}

.arrow-left {
  flex-direction: row-reverse;
}

/* ── Vertical arrow ──────────────────────────────────────── */
.arrow-v {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 100%;
  flex-shrink: 0;
}

.arrow-line-v {
  width: 2px;
  flex: 1;
  background: var(--w95-gray);
}

.arrow-head-v {
  font-size: 0.85rem;
  color: var(--w95-dark);
  line-height: 1;
  flex-shrink: 0;
}
</style>
