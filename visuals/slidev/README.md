# Slidev Visual Starter Packs

This workspace generates reusable visual assets for course labs:

- Static PNG exports for hero/content visuals
- Animated GIF exports from step-by-step slides
- Output paths aligned with `container-course/assets/generated/...`

## Decks Included

- `week-04-rbac-authz` -> Lab 5: RBAC Authorization Deep Dive
- `week-04-pod-security-admission` -> Lab 6: Pod Security Admission Deep Dive
- `week-08-gitops-loop` -> Lab 3: The GitOps Loop + Revert

## Prerequisites

Install dependencies:

```bash
cd container-course/visuals/slidev
npm install
```

Install Playwright Chromium (needed by Slidev export):

```bash
npx playwright install chromium
```

Ensure one GIF backend exists:

- `magick` (ImageMagick)
- or `convert` (ImageMagick)
- or `ffmpeg`

## Usage

Run one deck:

```bash
npm run export:deck -- week-04-rbac-authz
```

Run all decks:

```bash
npm run export:all
```

## Output Layout

Each deck writes to:

```text
container-course/assets/generated/<deck-id>/
  hero.png
  content.png
  flow.gif
  summary.md
  embed-snippet.md
  slides/
    slide-01.png
    slide-02.png
    ...
```

## README Embed Snippets

Use `embed-snippet.md` from each generated deck folder.

Example for RBAC lab README:

```markdown
![RBAC Authorization Hero](../../../assets/generated/week-04-rbac-authz/hero.png)
![RBAC Authorization Decision Flow](../../../assets/generated/week-04-rbac-authz/flow.gif)
```

