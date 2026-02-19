# Kubernetes Extension Interfaces Worksheet

## Part 1: Container Runtime Interface (CRI)

**Your cluster's container runtime:**
- Version: ________________________________
- Socket path: _____________________________
- CLI tool for debugging: ___________________

**Commands that helped you discover this:**
```bash
# Add your discovery commands here


```

---

## Part 2: Container Network Interface (CNI)

**Your cluster's CNI plugin:**
- Name: ____________________________________
- Configuration file path: __________________
- System pods: _____________________________

**CNI comparison table:**
| CNI Plugin | NetworkPolicy Support | Routing Method | CRDs Created |
|------------|----------------------|----------------|--------------|
| Kindnet    |                      |                |              |
| Calico     |                      |                |              |
| Cilium     |                      |                |              |
| Flannel    |                      |                |              |

---

## Part 3: Container Storage Interface (CSI)

**Your cluster's storage:**
- Default StorageClass: ________________________
- Provisioner: _________________________________
- System pods: ________________________________

**Cloud CSI drivers you might encounter:**
| Cloud Provider | CSI Driver Name | DaemonSet | Deployment |
|----------------|-----------------|-----------|------------|
| AWS            | ebs.csi.aws.com |           |            |
| GCP            |                 |           |            |
| Azure          |                 |           |            |

---

## Part 4: Troubleshooting Quick Reference

**When CRI fails, you see:**
- ___________________________________________
- ___________________________________________

**When CNI fails, you see:**
- ___________________________________________
- ___________________________________________

**When CSI fails, you see:**
- ___________________________________________
- ___________________________________________

**Key troubleshooting commands:**
```bash
# CRI diagnosis


# CNI diagnosis


# CSI diagnosis


```

---

## Reflection Questions

1. **Why does Kubernetes use these extension interfaces instead of hardcoding specific implementations?**

2. **Which interface would you troubleshoot first if pods are stuck in ContainerCreating?**

3. **How would you verify that a CNI plugin supports NetworkPolicy enforcement?**

4. **What happens to existing pods if you replace the CNI plugin?**

5. **In a production cluster, why might you choose Calico over Flannel for CNI?**