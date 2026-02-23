export function parsePayload() {
  const params = new URLSearchParams(window.location.search)
  const encoded = params.get('payload')

  if (!encoded) {
    return {
      scene: 'info-summary',
      title: 'Visual Preview Missing Payload',
      bullets: ['Pass a payload query string from build-visuals.mjs'],
      profile: 'industrial-control',
      frame: 0,
      totalFrames: 1,
    }
  }

  try {
    const text = decodeURIComponent(escape(window.atob(encoded)))
    return JSON.parse(text)
  } catch (error) {
    return {
      scene: 'info-summary',
      title: 'Invalid payload',
      bullets: [String(error)],
      profile: 'industrial-control',
      frame: 0,
      totalFrames: 1,
    }
  }
}

export function progressForFrame(frame = 0, totalFrames = 1) {
  if (totalFrames <= 1) {
    return 1
  }
  return Math.max(0, Math.min(1, frame / (totalFrames - 1)))
}
