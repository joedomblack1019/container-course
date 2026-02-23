<script setup>
import { computed } from 'vue'
import { parsePayload, progressForFrame } from './lib/payload'
import { sceneRegistry } from './scene-registry'

const payload = parsePayload()

const scene = computed(() => sceneRegistry[payload.scene] ?? sceneRegistry['info-summary'])
const progress = computed(() => progressForFrame(payload.frame, payload.totalFrames))

const sceneProps = computed(() => ({
  ...payload,
  progress: progress.value,
}))
</script>

<template>
  <main class="canvas" :data-profile="payload.profile || 'industrial-control'">
    <component :is="scene" v-bind="sceneProps" />
  </main>
</template>
