import GitOpsLoopScene from './scenes/GitOpsLoopScene.vue'
import EtcdReplicationScene from './scenes/EtcdReplicationScene.vue'
import InfoSummaryScene from './scenes/InfoSummaryScene.vue'
import DesktopScene from './scenes/DesktopScene.vue'

export const sceneRegistry = {
  'gitops-loop': GitOpsLoopScene,
  'etcd-replication': EtcdReplicationScene,
  'info-summary': InfoSummaryScene,
  'gitops-incident': DesktopScene,
}
