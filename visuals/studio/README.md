# Visual Studio (Markdown -> Visual Assets)

This workspace generates polished visual assets directly from markdown frontmatter.

It is designed for course docs that need visual breaks between text/code blocks:

- Hero image per lesson (`hero.png`)
- Animated concept flow GIFs (`flow.gif`, plus named gifs)
- Standout info cards (`info/*.png`)
- Ready-to-paste embed snippets (`embed-snippet.md`)

## Install

```bash
cd container-course/visuals/studio
npm install
npx playwright install chromium
```

Make sure `ffmpeg` exists on your machine for GIF generation.

## Lesson Input Format

Add frontmatter to any markdown file. The body is ignored by the renderer.

```yaml
---
id: week-08-gitops-loop
title: The GitOps Loop
visuals:
  profile: industrial-control
  hero:
    scene: gitops-loop
    title: GitOps Loop in One Look
  gifs:
    - name: gitops-flow
      scene: gitops-loop
      frames: 24
      fps: 8
  infoSlides:
    - name: summary
      scene: info-summary
      title: GitOps Mental Model
      bullets:
        - Git is the source of desired state.
        - Controllers reconcile continuously.
        - Revert commits become rollbacks.
---
```

## Generate Assets

```bash
npm run visuals:build -- examples/gitops-lesson.md
```

Output path:

```text
container-course/assets/generated/<id>/
  hero.png
  content.png (first info slide when present)
  flow.gif    (first gif when present)
  <named>.gif
  info/
    info-01.png
    <named>.png
  summary.md
  embed-snippet.md
  manifest.json
```

## Scene Catalog

Configured in `config/scenes.yaml`:

- `gitops-loop`
- `etcd-replication`
- `info-summary`

Profiles available:

- `industrial-control`
- `terminal-amber`
- `blueprint`
- `msdos-curses`
- `win98-classic`
