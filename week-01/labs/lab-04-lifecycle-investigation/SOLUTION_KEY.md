# Container Lifecycle Investigation - SOLUTION KEY

**Instructor Guide:** This document provides expected answers, example commands, common misconceptions, and teaching notes for the lifecycle investigation worksheet.

---

## Part 1: Understanding Container States

### Question 1.1: Stop vs Start vs Restart

**Expected Commands:**
```bash
docker run -d --name test-nginx nginx
docker ps  # Note the CONTAINER ID
docker stop test-nginx
docker ps -a  # Container still exists, status "Exited"
docker start test-nginx
docker ps  # Note the CONTAINER ID - it's the same!
```

**Expected Answer:**
"I used the same container. The container ID stayed the same before and after stopping and starting. `docker stop` and `docker start` work with an existing container; they don't create new ones."

**Common Misconceptions:**
- Students think `docker start` creates a new container (confusing it with `docker run`)
- Students don't realize stopped containers persist until explicitly removed

**Teaching Note:**
This establishes the fundamental concept: containers are **persistent objects** until removed. They have states (created, running, paused, stopped) but remain the same container.

---

### Question 1.2: Stop vs Kill

**Expected Commands:**
```bash
docker run -d --name stop-test nginx
docker run -d --name kill-test nginx

docker stop stop-test
docker kill kill-test

docker ps -a --format "{{.Names}}\t{{.Status}}"
# OR
docker inspect stop-test --format '{{.State.ExitCode}}'
docker inspect kill-test --format '{{.State.ExitCode}}'
```

**Expected Answer:**
"`docker stop` sends SIGTERM, waits for graceful shutdown (default 10s), then SIGKILL if needed. Exit code 0.
`docker kill` sends SIGKILL immediately, forcefully terminating the process. Exit code 137 (128 + 9 for SIGKILL)."

**Exit Codes:**
- `docker stop`: Usually 0 (clean exit)
- `docker kill`: 137 (128 + signal number 9)

**Common Misconceptions:**
- Students think they're the same ("both stop the container")
- Not understanding graceful vs forceful shutdown implications

**Teaching Note:**
This is critical for production. `docker stop` allows apps to finish requests, close database connections, etc. `docker kill` is for emergencies or when things hang.

**Deep Dive (Advanced):**
```bash
# Show the difference in action
docker run -d --name graceful nginx
docker stop graceful  # Takes ~1-2 seconds (nginx handles SIGTERM)

docker run -d --name forceful nginx
docker kill forceful  # Instant (no cleanup)
```

---

### Question 1.3: Created But Not Running

**Expected Commands:**
```bash
docker create --name created-test nginx
docker ps  # Not shown
docker ps -a  # Shows with status "Created"
docker exec created-test ls  # Fails!
```

**Expected Answer:**
"The container is in 'Created' state. I cannot exec into it because the main process hasn't started yet. `docker exec` requires a running container with PID namespace initialized."

**Common Error:**
```
Error response from daemon: Container created-test is not running
```

**Common Misconceptions:**
- Students think "create" means the same as "run"
- Not understanding that exec needs a running process tree

**Teaching Note:**
This reveals the container lifecycle states. `docker create` allocates resources and sets up the container but doesn't start it. Common in advanced workflows where you want to configure before starting.

**Why This Matters:**
Some orchestrators separate create and start phases for health checks, configuration validation, etc.

---

### Question 1.4: Paused Containers

**Expected Commands:**
```bash
docker run -d --name pause-test -p 8080:80 nginx
curl localhost:8080  # Works

docker pause pause-test
docker ps  # Still shows, STATUS: "Up X seconds (Paused)"
curl localhost:8080  # Hangs/times out
docker exec pause-test ls  # Fails!

docker unpause pause-test
curl localhost:8080  # Works again
```

**Expected Answer:**
"Paused containers show in `docker ps` with 'Paused' status. Network requests hang because the process is frozen. `docker exec` fails because you can't execute in a paused process namespace."

**Common Misconceptions:**
- Thinking pause = stop (they're very different)
- Not understanding that pause literally freezes the process mid-execution

**Teaching Note:**
Pause uses cgroups freezer. The process is suspended at the kernel level - all threads frozen, no CPU time. This is rarely used in practice but demonstrates Docker's control over process execution.

**When It's Used:**
- Taking filesystem snapshots (freeze, snapshot, unpause)
- Checkpointing (experimental feature)
- Debugging race conditions

---

## Part 2: Data Lifecycle

### Question 2.1: Survived Stop?

**Expected Commands:**
```bash
docker run -d --name data-test nginx
docker exec data-test sh -c 'echo "test data" > /tmp/myfile.txt'
docker exec data-test cat /tmp/myfile.txt  # Shows "test data"

docker stop data-test
docker start data-test

docker exec data-test cat /tmp/myfile.txt  # Still shows "test data"!
```

**Expected Answer:**
"Yes, the file is still there after stop/start. The container's filesystem is preserved when you stop a container. Only when you `docker rm` the container does its filesystem layer get deleted."

**Common Misconceptions:**
- Thinking containers are "stateless" and lose data on stop
- Confusing stop with remove

**Teaching Note:**
This is CRITICAL. Containers have a writable layer that persists across stop/start. This is why you can:
- Stop a database container and start it later with data intact
- Debug by stopping, examining, and restarting

**The Layer Model:**
```
[Writable Container Layer] <- Persists until docker rm
[Image Layer 3 (Read-only)]
[Image Layer 2 (Read-only)]
[Image Layer 1 (Read-only)]
```

---

### Question 2.2: Survived Remove?

**Expected Commands:**
```bash
docker run -d --name data-test nginx
docker exec data-test sh -c 'echo "test data" > /tmp/myfile.txt'

docker stop data-test
docker rm data-test

docker run -d --name data-test nginx
docker exec data-test cat /tmp/myfile.txt  # File not found!
```

**Expected Answer:**
"No, the file is gone. When I removed the container with `docker rm`, its writable layer was deleted. The new container started fresh from the image, which doesn't have my file."

**Common Misconceptions:**
- Thinking the image was modified
- Not understanding container vs image distinction

**Teaching Note:**
This is THE critical insight: **Changes to a container's filesystem are not changes to the image.**

```
Image (read-only blueprint)
    ↓ docker run creates
Container (image + writable layer)
    ↓ docker rm destroys
[writable layer deleted, image unchanged]
```

**The Big Reveal:**
"So how do you make permanent changes? You build a new image with a Dockerfile!"

**Advanced:** This is why we need volumes for databases - data must survive container removal.

---

### Question 2.3: Crashed Container Logs

**Expected Commands:**
```bash
docker run --name crasher nginx /bin/false
docker ps  # Not shown
docker ps -a  # Shows with status "Exited (1)"
docker logs crasher  # Works! (Though probably empty)
docker start crasher  # It crashes again immediately
```

**Expected Answer:**
"The container is in 'Exited' state with exit code 1. I can still get logs from stopped/crashed containers using `docker logs`. I can restart it, but it crashes again because the problem (the command /bin/false) is still there."

**Common Misconceptions:**
- Thinking crashed containers disappear
- Not knowing logs persist for stopped containers

**Teaching Note:**
This is huge for debugging. Crashed containers stick around so you can investigate:
```bash
docker logs crasher  # What was it trying to do?
docker inspect crasher  # How was it configured?
docker start crasher && docker logs -f crasher  # Watch it crash live
```

**Production Scenario:**
"Your app crashed at 3am. It's 9am now. Good news: the container and logs are still there!"

---

## Part 3: Lifecycle Commands

### Question 3.1: Restart Running Container

**Expected Commands:**
```bash
docker run -d --name restart-test nginx
BEFORE_ID=$(docker ps --filter name=restart-test --format "{{.ID}}")
echo "Before: $BEFORE_ID"

docker restart restart-test

AFTER_ID=$(docker ps --filter name=restart-test --format "{{.ID}}")
echo "After: $AFTER_ID"
```

**Expected Answer:**
"The container stops and starts, but keeps the same container ID. `docker restart` is equivalent to `docker stop` followed by `docker start` - it's the same container, just restarted."

**Common Misconceptions:**
- Thinking restart creates a new container
- Confusing restart with recreate

**Teaching Note:**
This is important for configuration changes. If you update an environment variable and restart, it won't take effect because the container config is set at creation time. You need to `docker rm` and `docker run` again.

**Advanced:**
```bash
docker run -d --name test -e VAR=old nginx
docker exec test env | grep VAR  # VAR=old
# Change VAR in your config...
docker restart test
docker exec test env | grep VAR  # Still VAR=old!
```

---

### Question 3.2: Renaming Containers

**Expected Commands:**
```bash
# Test 1: Running container
docker run -d --name old-name nginx
docker rename old-name new-name  # Works!
docker ps  # Shows "new-name"

# Test 2: Stopped container
docker stop new-name
docker rename new-name another-name  # Works!

# Test 3: Auto-named container
docker run -d nginx  # No --name flag
docker ps  # Note the random name like "eloquent_tesla"
docker rename eloquent_tesla my-name  # Works!
```

**Expected Answer:**
"Yes, you can rename both running and stopped containers. Even containers without an explicit --name flag can be renamed - Docker generates a random name that you can change."

**Common Misconceptions:**
- Thinking you can only rename stopped containers
- Not knowing auto-generated names can be changed

**Teaching Note:**
Container names are just labels, not intrinsic properties. This is useful when you realize a better name after creation.

**Production Tip:**
Always use `--name` in production for predictable references in monitoring, logs, etc.

---

### Question 3.3: The --rm Flag Mystery

**Expected Commands:**
```bash
docker run --rm -d --name auto-remove nginx
docker stop auto-remove
docker ps -a | grep auto-remove  # Nothing!
```

**Expected Answer:**
"The container disappeared! The `--rm` flag automatically removes the container when it stops. This is useful for one-off commands or tests where you don't need the container afterwards."

**Common Misconceptions:**
- Thinking --rm removes the image too
- Not understanding when this is useful

**Teaching Note:**
Great for:
- One-off commands: `docker run --rm ubuntu:22.04 cat /etc/os-release`
- CI/CD test containers
- Development experiments

Bad for:
- Anything where you need logs after the fact
- Debugging (container vanishes before you can inspect)

**Example Use Cases:**
```bash
# Good use of --rm
docker run --rm python:3.11 python -c "print('Hello')"
docker run --rm -v $(pwd):/work alpine tar czf /work/backup.tar.gz /data

# Bad use of --rm
docker run --rm -d my-api  # If it crashes, no logs to debug!
```

---

## Part 4: The Image-Container Relationship

### Question 4.1: Deleting Images

**Expected Commands:**
```bash
docker run -d --name c1 nginx
docker run -d --name c2 nginx
docker rmi nginx  # Fails!

# Error:
# Error response from daemon: conflict: unable to remove repository reference "nginx" (must force) - container <id> is using its referenced image

docker stop c1 c2
docker rm c1 c2
docker rmi nginx  # Works!
```

**Expected Answer:**
"Docker won't delete an image if containers exist that were created from it (even stopped containers). After I remove all containers, I can delete the image. This prevents orphaning containers."

**Common Misconceptions:**
- Thinking you can delete images with stopped containers
- Confusing image deletion with container deletion

**Teaching Note:**
The dependency chain: Image → Container. You can't delete the parent while children exist.

**Advanced - Force Delete:**
```bash
docker rmi -f nginx  # Removes the image tag, doesn't delete layers in use
# This is dangerous - containers become untagged but still reference the layers
```

---

### Question 4.2: Container Independence

**Expected Commands:**
```bash
docker run -d --name c1 nginx
docker run -d --name c2 nginx
docker run -d --name c3 nginx

docker exec c1 sh -c 'echo "from c1" > /tmp/file1.txt'
docker exec c2 sh -c 'echo "from c2" > /tmp/file2.txt'

docker exec c3 ls /tmp/
# Only sees standard system files, not file1.txt or file2.txt
```

**Expected Answer:**
"Container 3 cannot see the files from containers 1 and 2. Each container has its own isolated filesystem. Even though they're all from the same image, they each have their own writable layer."

**Common Misconceptions:**
- Thinking containers share a filesystem
- Not understanding container isolation

**Teaching Note:**
This is the CORE concept of containerization. Each container is isolated:
- Separate filesystem (mount namespace)
- Separate network (network namespace)
- Separate process tree (PID namespace)

**Visual:**
```
nginx Image (read-only)
    ├── Container 1 [writable layer with file1.txt]
    ├── Container 2 [writable layer with file2.txt]
    └── Container 3 [writable layer - clean]
```

**Advanced - Sharing Data:**
"If you want containers to share data, use volumes or bind mounts (Week 3)."

---

### Question 4.3: Image Immutability

**Expected Commands:**
```bash
docker run -d --name modify-test nginx
docker exec modify-test sh -c 'echo "modified" > /usr/share/nginx/html/index.html'
docker exec modify-test cat /usr/share/nginx/html/index.html  # Shows "modified"

docker stop modify-test
docker rm modify-test

docker run -d --name new-test nginx
docker exec new-test cat /usr/share/nginx/html/index.html  # Original nginx content!
```

**Expected Answer:**
"No, the new container doesn't have my changes. The modifications were in the container's writable layer, which was deleted when I removed the container. The image itself never changed.

To make permanent changes, I need to create a new image using a Dockerfile or `docker commit` (though Dockerfile is the proper way)."

**Common Misconceptions:**
- Thinking changes to a container modify the image
- Not understanding image immutability

**Teaching Note:**
This is THE critical concept for Week 2. Images are immutable. You don't modify them - you build new versions.

**The Mental Model:**
```
Image: Read-only blueprint
Container: Blueprint + changes
Remove container: Changes are lost
Build new image: Changes become part of the blueprint
```

**Advanced - Docker Commit (Show but discourage):**
```bash
docker run -d --name commit-test nginx
docker exec commit-test sh -c 'echo "new content" > /usr/share/nginx/html/index.html'
docker commit commit-test my-modified-nginx
docker run -d --name from-commit my-modified-nginx
docker exec from-commit cat /usr/share/nginx/html/index.html  # Shows "new content"
```

But emphasize: "This works but is bad practice. Use Dockerfiles for reproducibility!"

---

## Part 5: Real-World Debugging Scenario

### Question 5.1: The Crashing Container

**Expected Commands:**
```bash
docker run -d --name broken --restart always nginx /bin/false
docker ps -a  # Shows constant restarts

# Attempt 1: Try to exec (fails)
docker exec broken ls  # Error: container is not running (or is restarting)

# Solution 1: Override the command
docker run -d --name debug-broken nginx /bin/sleep infinity
docker exec -it debug-broken /bin/bash
# Now you can poke around

# Solution 2: Disable restart policy temporarily
docker update --restart=no broken
# Wait for it to crash and stay down
docker start broken  # Try to start manually for debugging
docker logs broken

# Solution 3: Run with different entrypoint
docker run -it --entrypoint /bin/bash nginx
# Explore the filesystem, test commands manually

# Solution 4: Inspect the failing container
docker inspect broken
# Look at .State.Error, .Config.Cmd, etc.
```

**Expected Answer:**
"I used multiple approaches:
1. Created a new container from the same image with `sleep infinity` to keep it alive
2. Disabled the restart policy with `docker update` so it stays stopped after crashing
3. Ran interactively with `--entrypoint /bin/bash` to explore manually
4. Used `docker logs` and `docker inspect` on the crashed container

In production, I'd use approach 2 (disable restart) or 1 (debug container) to investigate without affecting the failing container."

**Common Misconceptions:**
- Not knowing about `docker update --restart`
- Not thinking to run a separate debug container

**Teaching Note:**
This simulates a real production scenario. Students need to think creatively:

**Production Best Practices:**
1. Keep crashed containers for forensics
2. Disable auto-restart temporarily for investigation
3. Use `docker logs` extensively
4. Spin up a parallel debug container from the same image
5. Check `docker events` for recent history

**Advanced Debugging:**
```bash
# See recent container events
docker events --filter container=broken --since 5m

# Get detailed state info
docker inspect broken --format '{{json .State}}' | jq

# Copy files out of a stopped container
docker cp broken:/var/log/app.log ./
```

---

### Question 5.2: Container Resource Detective

**Expected Commands:**
```bash
docker run -d --name resource-test nginx

# Memory usage
docker stats resource-test --no-stream

# IP address
docker inspect resource-test --format '{{.NetworkSettings.IPAddress}}'
# OR
docker inspect resource-test | grep IPAddress

# Exposed ports
docker inspect resource-test --format '{{.Config.ExposedPorts}}'
docker port resource-test

# Restart policy
docker inspect resource-test --format '{{.HostConfig.RestartPolicy.Name}}'
```

**Expected Answers:**
- Memory: ~2-5 MB for idle nginx
- IP: Usually 172.17.0.X (default bridge network)
- Ports: 80/tcp
- Restart policy: "no" (default)

**Common Misconceptions:**
- Not knowing about `docker inspect`
- Not knowing `--format` for filtering output

**Teaching Note:**
`docker inspect` is your best friend. It shows EVERYTHING about a container:
- Configuration
- State
- Network settings
- Volumes
- Environment variables
- Resource limits
- And more...

**Pro Tips:**
```bash
# Get JSON output
docker inspect resource-test

# Filter with --format (Go templates)
docker inspect resource-test --format '{{.State.Status}}'

# Use jq for complex queries
docker inspect resource-test | jq '.NetworkSettings.Networks'

# See all environment variables
docker inspect resource-test --format '{{.Config.Env}}'
```

---

## Part 6: Lifecycle Troubleshooting

### Question 6.1: Port Already in Use

**Expected Commands:**
```bash
docker run -d --name first -p 8080:80 nginx
docker run -d --name second -p 8080:80 nginx  # Fails!

# Error:
# Error response from daemon: driver failed programming external connectivity on endpoint second: 
# Bind for 0.0.0.0:8080 failed: port is already allocated

# Find what's using the port (if you didn't know)
docker ps --filter "publish=8080"
# OR on Linux:
sudo lsof -i :8080
# OR
sudo netstat -tlnp | grep 8080
```

**Expected Answer:**
"The error says 'port is already allocated'. Only one container can bind to a host port at a time. To fix it, I can:
1. Use a different host port: `-p 8081:80`
2. Stop the first container
3. Use `docker ps` to find what's using the port"

**Common Misconceptions:**
- Not understanding that host ports are exclusive
- Confusing host port with container port

**Teaching Note:**
This is the most common beginner issue. Port mapping syntax:
```
-p HOST_PORT:CONTAINER_PORT
   └─ Must be unique across all containers on this host
               └─ Can be same across containers
```

**Example:**
```bash
# This works - different host ports
docker run -d -p 8080:80 nginx
docker run -d -p 8081:80 nginx
docker run -d -p 8082:80 nginx

# All three containers expose port 80 internally
# But bind to different host ports
```

---

### Question 6.2: Container Name Conflicts

**Expected Commands:**
```bash
docker run -d --name test nginx
docker stop test  # Container still exists!
docker run -d --name test nginx  # Fails!

# Error:
# Error response from daemon: Conflict. The container name "/test" is already in use by container "abc123"

# Solutions:
# Option 1: Remove the old one
docker rm test
docker run -d --name test nginx  # Works!

# Option 2: Use a different name
docker run -d --name test2 nginx

# Option 3: Remove the old container automatically
docker rm -f test
docker run -d --name test nginx
```

**Expected Answer:**
"Container names must be unique, even for stopped containers. To fix it, I need to remove the stopped container first with `docker rm test`, or use a different name."

**Common Misconceptions:**
- Thinking stopped containers don't count
- Not knowing names must be unique

**Teaching Note:**
Names are unique identifiers. Docker uses them for:
- DNS resolution (in user-defined networks)
- References in commands
- Dependencies (links, network aliases)

**Best Practice:**
Use meaningful, unique names in production:
```bash
# Good
docker run -d --name web-prod nginx
docker run -d --name web-staging nginx

# Bad
docker run -d --name nginx nginx  # Not specific
```

**Quick Cleanup Pattern:**
```bash
# Remove if exists, don't error if it doesn't
docker rm -f mycontainer 2>/dev/null || true
docker run -d --name mycontainer nginx
```

---

### Question 6.3: Finding Lost Containers

**Expected Commands:**
```bash
# All containers (running and stopped)
docker ps -a

# Only stopped containers
docker ps -a --filter status=exited

# Only running containers
docker ps
# OR
docker ps --filter status=running

# Remove all stopped containers
docker container prune
# OR
docker rm $(docker ps -aq --filter status=exited)

# Get count
docker ps -a -q | wc -l  # Total
docker ps -q | wc -l     # Running
```

**Expected Answers:**
- All containers: `docker ps -a`
- Only stopped: `docker ps -a --filter status=exited`
- Remove all stopped: `docker container prune` (safest) or `docker rm $(docker ps -aq --filter status=exited)`

**Common Misconceptions:**
- Not knowing about `-a` flag
- Not knowing about filters
- Trying to manually delete one by one

**Teaching Note:**
Containers accumulate during development. Regular cleanup is important.

**Cleanup Commands Cheat Sheet:**
```bash
# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything not in use
docker system prune

# Nuclear option (use with caution!)
docker system prune -a --volumes
```

**Safe Production Pattern:**
```bash
# See what would be deleted first
docker container prune --dry-run

# Then actually delete
docker container prune -f
```

---

## Final Reflection - Grading Notes

### What surprised you most about container lifecycle?

**Look for insights like:**
- "I didn't realize stopped containers persist"
- "Changes to containers don't affect the image"
- "Containers are completely isolated from each other"
- "You can get logs from crashed containers"

**Red flags:**
- Very vague answers
- "Nothing surprised me" (probably didn't engage deeply)

### What's one thing you'll do differently now?

**Good answers:**
- "Always use --name for easier management"
- "Check docker ps -a before trying to reuse a name"
- "Use --rm for one-off commands"
- "Remember to docker rm containers I don't need anymore"

**Red flags:**
- Generic or copied from docs

### Explain image vs container

**Good explanations (various analogies work):**
- "Image is like a class, container is like an instance"
- "Image is the recipe, container is the cake"
- "Image is a read-only template, container is a running copy with changes"
- "Image is the program on disk, container is the running process"

**Red flags:**
- "They're basically the same"
- "Container is just a running image" (missing the persistence aspect)
- Copy-paste from documentation

**Grading Rubric:**
- **Excellent:** Uses own analogy, demonstrates understanding of mutability, persistence, and relationship
- **Good:** Correctly identifies image as template and container as instance, mentions one is read-only
- **Satisfactory:** Basic understanding but vague or incomplete
- **Needs review:** Fundamental misconceptions evident

---

## Bonus Challenges - Solutions

### The Zombie Hunter

**Commands:**
```bash
docker ps      # Shows running
docker ps -a   # Shows all (running + stopped)
```

**Answer:**
Stopped containers stick around because:
1. You might need their logs
2. You might need to restart them
3. You might need to inspect their configuration
4. Docker doesn't automatically clean up (you must explicitly remove)

This is actually a feature, not a bug - it's for forensics and debugging.

### The Network Detective

**Commands:**
```bash
docker network ls  # See default networks
docker run -d --name c1 nginx
docker run -d --name c2 nginx

# Get IPs
docker inspect c1 --format '{{.NetworkSettings.IPAddress}}'
docker inspect c2 --format '{{.NetworkSettings.IPAddress}}'

# Try to ping from c1 to c2
docker exec c1 ping -c 2 <c2-ip>  # Works on default bridge!

# Try by name
docker exec c1 ping c2  # Fails - no DNS on default bridge

# Create user-defined network with DNS
docker network create my-net
docker run -d --name c3 --network my-net nginx
docker run -d --name c4 --network my-net nginx
docker exec c3 ping c4  # Works by name!
```

**Answer:**
Containers on the same Docker network can communicate by IP. On user-defined networks, they can also use DNS (container names). On the default bridge, only IP works.

### The Volume Mystery

**Commands:**
```bash
docker run -d --name vol-test -v /data nginx
docker exec vol-test sh -c 'echo "important" > /data/file.txt'

# Find the volume
docker inspect vol-test --format '{{.Mounts}}'
# Shows something like: [{volume abc123... /var/lib/docker/volumes/abc123/_data /data local  true }]

# Get the volume name
VOLUME=$(docker inspect vol-test --format '{{(index .Mounts 0).Name}}')
echo $VOLUME

docker rm -f vol-test

# Volume still exists!
docker volume ls | grep $VOLUME

# The file is still there on the host
sudo ls /var/lib/docker/volumes/$VOLUME/_data/

# Clean up
docker volume rm $VOLUME
```

**Answer:**
The file went into a Docker volume, which persists even after the container is removed. Volumes have their own lifecycle independent of containers. This is how databases persist data!

---

## Teaching Reminders

1. **Encourage experimentation:** Wrong answers that lead to discovery are better than right answers copied from Stack Overflow.

2. **Watch for copy-paste:** If answers are identical to documentation, they didn't experiment.

3. **Look for command evidence:** Students should show what they tried, not just the final answer.

4. **Use misconceptions as teaching moments:** Common errors reveal gaps in understanding - address these in review.

5. **Emphasize the mental model:** Image (immutable) → Container (mutable) → Remove (image unchanged)

6. **Connect to upcoming topics:** 
   - "This is why we need volumes" (Week 3)
   - "This is why we use Docker Compose" (Week 3)
   - "This is why we build new images instead of modifying containers" (Week 2)

---

## Common Student Struggles

### Struggle: "I don't know what commands to try"

**Help them with:**
"Start with `docker --help` and `docker ps --help`. Try things and see what happens. The worst that happens is you delete a test container."

### Struggle: "My answers are different from my classmate's"

**Response:**
"That's okay! As long as your commands demonstrate the concept and your reasoning is sound. There are many ways to discover the same truth."

### Struggle: "I broke something and can't continue"

**Rescue:**
```bash
# Nuclear reset
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker system prune -af
```

Then start fresh.

### Struggle: "This is taking longer than 45 minutes"

**Response:**
"That's fine. This is exploration, not a race. Some questions might take 2 minutes, others might take 10. The learning is in the experimentation."

---

## Assessment Criteria

**Excellent (A):**
- Demonstrates deep understanding through experimentation
- Commands show creative problem-solving
- Insights go beyond the obvious
- Can explain concepts in own words with analogies
- Identifies implications for production use

**Good (B):**
- Correct understanding of core concepts
- Commands show systematic exploration
- Answers are accurate and demonstrate learning
- Can explain image/container relationship clearly

**Satisfactory (C):**
- Basic understanding present
- Some commands shown but limited exploration
- Answers correct but surface-level
- May have some misconceptions

**Needs Improvement (D/F):**
- Fundamental misunderstandings persist
- Little evidence of hands-on experimentation
- Answers appear copied without understanding
- Cannot explain basic concepts

---

## Extension for Advanced Students

If students finish early and want more:

1. **Multi-stage container operations:**
   ```bash
   # Create a data-only container
   docker create --name data-source -v /data nginx
   docker run --rm --volumes-from data-source nginx sh -c 'echo "shared" > /data/file.txt'
   docker run --rm --volumes-from data-source nginx cat /data/file.txt
   ```

2. **Container resource limits:**
   ```bash
   docker run -d --name limited --memory="100m" --cpus="0.5" nginx
   docker stats limited
   # Try to exceed limits and see what happens
   ```

3. **Custom networks and isolation:**
   ```bash
   docker network create net1
   docker network create net2
   docker run -d --name c1 --network net1 nginx
   docker run -d --name c2 --network net2 nginx
   # Can c1 reach c2?
   ```

These preview Week 3 (Compose) and Week 6 (Kubernetes resources/networking) concepts.
