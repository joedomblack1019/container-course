#!/usr/bin/env node
import fs from 'node:fs/promises'
import path from 'node:path'
import { spawn } from 'node:child_process'
import matter from 'gray-matter'
import yaml from 'js-yaml'
import { chromium } from 'playwright'
import { createServer } from 'vite'

const WIDTH = 1960
const HEIGHT = 1104
const PORT = 4179

const scriptDir = path.dirname(new URL(import.meta.url).pathname)
const studioRoot = path.resolve(scriptDir, '..')
const courseRoot = path.resolve(studioRoot, '../..')
const generatedRoot = path.join(courseRoot, 'assets', 'generated')
const configPath = path.join(studioRoot, 'config', 'scenes.yaml')

function usage() {
  console.log('Usage: npm run visuals:build -- <markdown-file>')
}

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

function toPayload(scene) {
  const text = JSON.stringify(scene)
  return Buffer.from(text, 'utf8').toString('base64')
}

function safeName(name, fallback) {
  if (!name || typeof name !== 'string') return fallback
  return name.toLowerCase().replace(/[^a-z0-9-]+/g, '-').replace(/^-+|-+$/g, '') || fallback
}

async function runFfmpeg(framesDir, frames, fps, outFile) {
  const inputPattern = path.join(framesDir, 'frame-%03d.png')
  const args = [
    '-y',
    '-framerate',
    String(fps),
    '-i',
    inputPattern,
    '-vf',
    'split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3',
    '-loop',
    '0',
    outFile,
  ]

  await new Promise((resolve, reject) => {
    const child = spawn('ffmpeg', args, { stdio: 'ignore' })
    child.on('error', reject)
    child.on('close', (code) => {
      if (code === 0) {
        resolve()
        return
      }
      reject(new Error(`ffmpeg exited with code ${code}.`))
    })
  })
}

async function ensureDir(dirPath) {
  await fs.mkdir(dirPath, { recursive: true })
}

async function main() {
  const lessonArg = process.argv[2]
  if (!lessonArg) {
    usage()
    process.exit(1)
  }

  const lessonPath = path.resolve(process.cwd(), lessonArg)
  if (!(await exists(lessonPath))) {
    throw new Error(`Lesson markdown not found: ${lessonPath}`)
  }

  const markdown = await fs.readFile(lessonPath, 'utf8')
  const parsed = matter(markdown)
  const id = parsed.data.id || path.basename(lessonPath, path.extname(lessonPath))
  const title = parsed.data.title || id
  const visuals = parsed.data.visuals || {}

  if (!visuals.hero?.scene) {
    throw new Error('Missing visuals.hero.scene in frontmatter.')
  }

  const configText = await fs.readFile(configPath, 'utf8')
  const sceneConfig = yaml.load(configText)
  const profiles = sceneConfig?.profiles || {}
  const scenes = sceneConfig?.scenes || {}
  const profile = visuals.profile || 'industrial-control'

  if (!profiles[profile]) {
    throw new Error(`Unknown profile: ${profile}`)
  }

  const outputDir = path.join(generatedRoot, id)
  const infoDir = path.join(outputDir, 'info')
  await ensureDir(outputDir)
  await ensureDir(infoDir)

  const server = await createServer({
    root: studioRoot,
    logLevel: 'error',
    server: {
      host: '127.0.0.1',
      port: PORT,
    },
  })

  await server.listen()

  const browser = await chromium.launch()
  const context = await browser.newContext({
    viewport: { width: WIDTH, height: HEIGHT },
    deviceScaleFactor: 1,
  })
  const page = await context.newPage()

  async function renderPng(sceneData, outputFile) {
    if (!scenes[sceneData.scene]) {
      throw new Error(`Unknown scene "${sceneData.scene}" in ${outputFile}`)
    }

    const payload = toPayload({
      profile,
      frame: 0,
      totalFrames: 1,
      ...sceneData,
    })
    await page.goto(`http://127.0.0.1:${PORT}/?payload=${encodeURIComponent(payload)}`)
    await page.waitForTimeout(120)
    await page.evaluate(() => document.fonts.ready)
    await page.screenshot({ path: outputFile, type: 'png' })
  }

  async function renderGif(sceneData, outputFile) {
    if (!scenes[sceneData.scene]) {
      throw new Error(`Unknown scene "${sceneData.scene}" for gif ${outputFile}`)
    }

    const frames = Math.max(8, Number(sceneData.frames || 24))
    const fps = Math.max(4, Number(sceneData.fps || 8))
    const framesDir = await fs.mkdtemp(path.join(outputDir, '.frames-'))

    try {
      for (let frame = 0; frame < frames; frame += 1) {
        const payload = toPayload({
          profile,
          ...sceneData,
          frame,
          totalFrames: frames,
        })
        const framePath = path.join(framesDir, `frame-${String(frame).padStart(3, '0')}.png`)
        await page.goto(`http://127.0.0.1:${PORT}/?payload=${encodeURIComponent(payload)}`)
        await page.waitForTimeout(60)
        await page.evaluate(() => document.fonts.ready)
        await page.screenshot({ path: framePath, type: 'png' })
      }

      await runFfmpeg(framesDir, frames, fps, outputFile)
    } finally {
      await fs.rm(framesDir, { recursive: true, force: true })
    }
  }

  try {
    const heroData = {
      title,
      ...visuals.hero,
    }
    await renderPng(heroData, path.join(outputDir, 'hero.png'))

    const infoSlides = Array.isArray(visuals.infoSlides) ? visuals.infoSlides : []
    const infoOutputs = []

    for (let index = 0; index < infoSlides.length; index += 1) {
      const info = infoSlides[index]
      const sceneData = {
        scene: info.scene || 'info-summary',
        title: info.title || `${title} Summary`,
        subtitle: info.subtitle,
        bullets: info.bullets || [],
      }
      const numericName = `info-${String(index + 1).padStart(2, '0')}.png`
      const named = `${safeName(info.name, `info-${index + 1}`)}.png`
      const numericPath = path.join(infoDir, numericName)
      const namedPath = path.join(infoDir, named)

      await renderPng(sceneData, numericPath)
      if (namedPath !== numericPath) {
        await fs.copyFile(numericPath, namedPath)
      }
      infoOutputs.push({ name: info.name || `info-${index + 1}`, file: `info/${named}` })
    }

    if (infoSlides.length > 0) {
      await fs.copyFile(path.join(infoDir, 'info-01.png'), path.join(outputDir, 'content.png'))
    }

    const gifs = Array.isArray(visuals.gifs) ? visuals.gifs : []
    const gifOutputs = []

    for (let index = 0; index < gifs.length; index += 1) {
      const gif = gifs[index]
      const name = safeName(gif.name, `flow-${index + 1}`)
      const fileName = `${name}.gif`
      const outFile = path.join(outputDir, fileName)
      await renderGif(
        {
          scene: gif.scene,
          variant: gif.variant,
          title: gif.title || title,
          subtitle: gif.subtitle,
          bullets: gif.bullets || [],
          frames: gif.frames,
          fps: gif.fps,
        },
        outFile,
      )
      gifOutputs.push({ name, file: fileName })
    }

    if (gifOutputs.length > 0) {
      await fs.copyFile(path.join(outputDir, gifOutputs[0].file), path.join(outputDir, 'flow.gif'))
    }

    const sourceRel = path.relative(courseRoot, lessonPath)
    const summaryLines = [
      `# ${title}`,
      '',
      `- Visual ID: \`${id}\``,
      `- Source markdown: \`${sourceRel}\``,
      `- Profile: \`${profile}\``,
      `- Generated assets:`,
      '  - `hero.png`',
    ]

    if (infoSlides.length > 0) {
      summaryLines.push('  - `content.png`')
      summaryLines.push('  - `info/*.png`')
    }
    if (gifOutputs.length > 0) {
      summaryLines.push('  - `flow.gif`')
      for (const gif of gifOutputs) {
        summaryLines.push(`  - \`${gif.file}\``)
      }
    }

    await fs.writeFile(path.join(outputDir, 'summary.md'), `${summaryLines.join('\n')}\n`, 'utf8')

    const embedLines = [`![${title} Hero](../../../assets/generated/${id}/hero.png)`]
    if (gifOutputs.length > 0) {
      embedLines.push(`![${title} Flow](../../../assets/generated/${id}/${gifOutputs[0].file})`)
    }
    if (infoSlides.length > 0) {
      embedLines.push(`![${title} Concept Summary](../../../assets/generated/${id}/info/info-01.png)`)
    }
    await fs.writeFile(path.join(outputDir, 'embed-snippet.md'), `${embedLines.join('\n')}\n`, 'utf8')

    const manifest = {
      id,
      title,
      source: sourceRel,
      profile,
      dimensions: { width: WIDTH, height: HEIGHT },
      hero: 'hero.png',
      flow: gifOutputs[0]?.file || null,
      gifs: gifOutputs,
      info: infoOutputs,
      generatedAt: new Date().toISOString(),
    }
    await fs.writeFile(path.join(outputDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8')

    console.log(`Generated visual bundle at ${path.relative(courseRoot, outputDir)}`)
  } finally {
    await context.close()
    await browser.close()
    await server.close()
  }
}

main().catch((error) => {
  console.error(error.message)
  process.exit(1)
})
