<script setup>
const props = defineProps({
  title: { type: String, default: 'Concept Summary' },
  subtitle: { type: String, default: 'High-signal notes for fast recall.' },
  bullets: { type: Array, default: () => [] },
})

const fallbackBullets = [
  'No bullets provided. Add visuals.infoSlides[].bullets in frontmatter.',
]
</script>

<template>
  <section class="scene">
    <article class="window shell">
      <div class="title-bar">
        <div class="title-bar-text">Concept Brief.exe</div>
        <div class="title-bar-controls">
          <button aria-label="Minimize" />
          <button aria-label="Maximize" />
          <button aria-label="Close" />
        </div>
      </div>

      <div class="window-body body-grid">
        <section class="left-col">
          <div class="sunken-panel heading-panel">
            <p class="eyebrow">Course Signal Card</p>
            <h1 class="title">{{ title }}</h1>
            <p class="subtitle">{{ subtitle }}</p>
          </div>

          <div class="sunken-panel bullets-panel">
            <ul class="list">
              <li v-for="(item, index) in (bullets.length ? bullets : fallbackBullets)" :key="item + index">
                <span class="index">{{ String(index + 1).padStart(2, '0') }}.</span>
                <span class="item">{{ item }}</span>
              </li>
            </ul>
          </div>
        </section>

        <aside class="right-col">
          <fieldset>
            <legend>Status</legend>
            <p>Lesson: Ready</p>
            <p>Theme: Win98 Classic</p>
            <p>Purpose: Visual break</p>
          </fieldset>

          <fieldset>
            <legend>Checklist</legend>
            <p>[X] Fast scanability</p>
            <p>[X] Concept anchors</p>
            <p>[X] Strong contrast</p>
          </fieldset>

          <fieldset>
            <legend>Commands</legend>
            <pre>git revert &lt;sha&gt;
flux reconcile kustomization app
kubectl get events --sort-by=.lastTimestamp</pre>
          </fieldset>
        </aside>
      </div>

      <section class="status-bar">
        <p class="status-bar-field">F1 Help</p>
        <p class="status-bar-field">F5 Refresh</p>
        <p class="status-bar-field">Win98 Mode</p>
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
  grid-template-columns: 1.65fr 0.85fr;
  gap: 12px;
  min-height: 0;
}

.left-col {
  display: grid;
  grid-template-rows: auto 1fr;
  gap: 10px;
  min-height: 0;
}

.sunken-panel {
  border: 2px solid;
  border-color: #808080 #ffffff #ffffff #808080;
  background: #ffffff;
  padding: 10px;
}

.heading-panel {
  display: grid;
  gap: 6px;
}

.title {
  margin: 0;
  font-size: 2.4rem;
  line-height: 1.02;
  color: #000080;
}

.subtitle {
  margin: 0;
  font-size: 1.05rem;
  color: #111;
}

.bullets-panel {
  min-height: 0;
}

.list {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 8px;
  height: 100%;
  grid-auto-rows: 1fr;
}

.list li {
  display: grid;
  grid-template-columns: 58px 1fr;
  align-items: center;
  border: 1px solid #7f7f7f;
  background: #f3f3f3;
  min-height: 0;
}

.index {
  height: 100%;
  display: grid;
  place-items: center;
  font-family: var(--mono-font);
  font-size: 1.2rem;
  color: #000080;
  border-right: 1px solid #b5b5b5;
  background: #dfdfdf;
}

.item {
  padding: 8px 12px;
  font-size: 1.6rem;
  line-height: 1.2;
  font-family: var(--mono-font);
}

.right-col {
  display: grid;
  gap: 10px;
  grid-template-rows: repeat(3, 1fr);
}

fieldset {
  margin: 0;
  min-inline-size: 0;
  border: 2px groove #dfdfdf;
  padding: 10px;
  background: #efefef;
}

legend {
  padding: 0 6px;
  font-weight: 700;
  color: #000080;
}

fieldset p {
  margin: 0;
  line-height: 1.4;
  font-size: 1rem;
}

pre {
  margin: 0;
  white-space: pre-wrap;
  font-family: var(--mono-font);
  font-size: 1.05rem;
  line-height: 1.25;
}
</style>
