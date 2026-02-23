// ── Narrative script for the "GitOps Incident Response" desktop scene ──────────
//
// Acts define time slices of the 0→1 progress range.
// DesktopScene.vue reads this data and derives all window states from it.

export const ACTS = [
  { id: 'idle',        from: 0.00, to: 0.05, label: 'Routine checks' },
  { id: 'discovery',   from: 0.05, to: 0.24, label: 'CrashLoopBackOff detected' },
  { id: 'argocd',      from: 0.24, to: 0.40, label: 'ArgoCD reports Degraded' },
  { id: 'git-history', from: 0.40, to: 0.56, label: 'Pinpointing bad commit' },
  { id: 'revert',      from: 0.56, to: 0.74, label: 'Revert and push fix' },
  { id: 'reconcile',   from: 0.74, to: 0.89, label: 'ArgoCD reconciling' },
  { id: 'confirm',     from: 0.89, to: 1.00, label: 'Service restored' },
]

// ── Window layout (pixel positions for 1960×1104 canvas, larger windows) ────────
export const WINDOW_DEFS = {
  cmd: {
    id:    'cmd',
    title: 'Command Prompt',
    icon:  '💻',
    pos:   { x: 42,  y: 42,  w: 1320, h: 540 },
  },
  argo: {
    id:    'argo',
    title: 'ArgoCD — production',
    icon:  '⎈',
    pos:   { x: 620, y: 74,  w: 1220, h: 590 },
  },
  git: {
    id:    'git',
    title: 'Git History — main',
    icon:  '📋',
    pos:   { x: 140, y: 30,  w: 1420, h: 640 },
  },
  pods: {
    id:    'pods',
    title: 'kubectl — production',
    icon:  '🐳',
    pos:   { x: 70,  y: 310, w: 1620, h: 460 },
  },
  chat: {
    id:    'chat',
    title: 'Instant Message - PlatformOps',
    icon:  '💬',
    pos:   { x: 1360, y: 120, w: 520, h: 470 },
  },
  ceochat: {
    id:    'ceochat',
    title: 'Instant Message - CEO_BigBoss',
    icon:  '👔',
    pos:   { x: 1280, y: 600, w: 380, h: 280 },
  },
  browser: {
    id:    'browser',
    title: 'Internet Explorer - Runbook',
    icon:  '🌐',
    pos:   { x: 300, y: 120, w: 900, h: 500 },
  },
}

// ── CMD terminal lines ────────────────────────────────────────────────────────
// Discovery section: reveals progressively during the 'discovery' act
export const CMD_DISCOVERY = [
  { type: 'comment', text: '# morning check — are all production pods healthy?' },
  { type: 'input',   text: 'kubectl get pods -n production' },
  { type: 'output',  text: 'NAME                           READY   STATUS             RESTARTS   AGE' },
  { type: 'error',   text: 'web-deploy-7d9f4b-xkj2p        0/1     CrashLoopBackOff   4          8m' },
  { type: 'output',  text: 'redis-649c8d77b-r9xzp          1/1     Running            0          2d' },
  { type: 'output',  text: 'postgres-84fd5c89b-ppqt8       1/1     Running            0          2d' },
]

// Revert section: reveals progressively during the 'revert' act
export const CMD_REVERT = [
  { type: 'comment', text: '# found the bad commit — reverting it now' },
  { type: 'input',   text: 'git revert a3f91c2 --no-edit' },
  { type: 'output',  text: '[main f4e2b9a] Revert "feat: bump web replicas to 10"' },
  { type: 'output',  text: ' 1 file changed, 1 insertion(+), 1 deletion(-)' },
  { type: 'input',   text: 'git push origin main' },
  { type: 'success', text: '✓ ArgoCD: new revision detected — syncing...' },
]

// ── Git history commits ───────────────────────────────────────────────────────
export const GIT_COMMITS = [
  { sha: 'a3f91c2', msg: 'feat: bump web replicas to 10',  author: 'jg',  time: '9 min ago',  bad: true  },
  { sha: '7b2e4d1', msg: 'fix: update configmap value',    author: 'jg',  time: '2 hours ago',bad: false },
  { sha: '3c8a901', msg: 'chore: bump chart version',      author: 'ops', time: '1 day ago',  bad: false },
  { sha: '1d0f234', msg: 'feat: add liveness probe',       author: 'ops', time: '3 days ago', bad: false },
  { sha: 'd9e7b52', msg: 'fix: postgres conn pool size',   author: 'jg',  time: '5 days ago', bad: false },
]

// ── Per-act derived state ─────────────────────────────────────────────────────
// Which windows are visible and focused in each act
export const ACT_WINDOW_STATE = {
  idle:        { visible: ['cmd', 'chat'],                                focused: 'cmd',     argoStatus: null,       podPhase: null },
  discovery:   { visible: ['cmd', 'chat'],                               focused: 'cmd',     argoStatus: null,       podPhase: null },
  argocd:      { visible: ['cmd', 'argo', 'chat', 'ceochat'],            focused: 'argo',    argoStatus: 'degraded', podPhase: null },
  'git-history':{ visible: ['cmd', 'argo', 'git', 'chat'],               focused: 'git',     argoStatus: 'degraded', podPhase: null },
  revert:      { visible: ['cmd', 'argo', 'git', 'chat'],                focused: 'cmd',     argoStatus: 'syncing',  podPhase: null },
  reconcile:   { visible: ['cmd', 'argo', 'chat'],                       focused: 'argo',    argoStatus: 'healthy',  podPhase: null },
  confirm:     { visible: ['cmd', 'argo', 'pods', 'chat'],               focused: 'pods',    argoStatus: 'healthy',  podPhase: 'healthy' },
}
