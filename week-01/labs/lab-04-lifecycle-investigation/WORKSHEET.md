# Container Lifecycle Investigation

**Time:** 30-45 minutes  
**Type:** Independent exploration  
**Deliverable:** This completed worksheet with your answers

---

## Instructions

You've run containers in Lab 1 and Lab 2. Now it's time to **really** understand how the container lifecycle works.

**Rules:**
1. Answer each question by **running commands and observing the results**
2. Write your answers **in your own words** (no copy-paste from docs)
3. Include the **commands you ran** to discover the answer
4. Mark any surprises or "aha!" moments with 💡

**You'll learn more from being wrong and figuring out why than from being right immediately.**

---

## Part 1: Understanding Container States

### Question 1.1: Stop vs Start vs Restart

Start an nginx container, then stop it, then start it again.

**Question:** Did you use the same container or create a new one? How can you tell?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**💡 Aha moment (if any):**

---

### Question 1.2: Stop vs Kill

**Question:** What's the difference between `docker stop` and `docker kill`? 

**Experiment:** 
- Run two nginx containers
- `docker stop` one
- `docker kill` the other  
- Check their exit codes

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**Exit codes I observed:**

---

### Question 1.3: Created But Not Running

**Question:** Create a container but don't start it (hint: `docker create`). What state is it in? Can you exec into it? Why or why not?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

---

### Question 1.4: Paused Containers

**Question:** Pause a running nginx container. Can you still see it in `docker ps`? What happens if you try to curl it? What about `docker exec`?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**What worked / what didn't:**

---

## Part 2: Data Lifecycle

### Question 2.1: Survived Stop?

**Experiment:**
1. Start nginx
2. Exec in and create a file: `echo "test" > /tmp/myfile.txt`
3. Stop the container
4. Start it again
5. Exec in and check if the file exists

**Question:** Is the file still there after stop/start? Why or why not?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

---

### Question 2.2: Survived Remove?

**Experiment:**
1. Start nginx
2. Exec in and create a file: `echo "test" > /tmp/myfile.txt`
3. Stop the container
4. **Remove** the container (`docker rm`)
5. Start a **new** container from the same image
6. Check if the file exists

**Question:** Is the file still there after rm + new container? Why or why not?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**💡 What does this tell you about the difference between containers and images?**

---

### Question 2.3: Crashed Container Logs

**Experiment:**
Run a container that crashes immediately:
```bash
docker run --name crasher nginx /bin/false
```

**Questions:** 
- What state is the container in?
- Can you still get its logs?
- Can you restart it?

**Commands I ran:**
```bash
# Your commands here
```

**My answers:**

---

## Part 3: Lifecycle Commands

### Question 3.1: Restart Running Container

**Question:** What happens if you `docker restart` a container that's already running? Does it get a new container ID?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

---

### Question 3.2: Renaming Containers

**Questions:**
- Can you rename a running container?
- Can you rename a stopped container?
- If you start a container without `--name`, can you still rename it?

**Commands I ran:**
```bash
# Your commands here
```

**My answers:**

---

### Question 3.3: The --rm Flag Mystery

**Experiment:**
1. Start a container with the `--rm` flag
2. Stop it
3. Try to find it with `docker ps -a`

**Question:** Where did it go? When is `--rm` useful?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

---

## Part 4: The Image-Container Relationship

### Question 4.1: Deleting Images

**Experiment:**
1. Run 2 containers from nginx (let them keep running)
2. Try to delete the nginx image

**Question:** What happens? Why?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**Now stop and remove all containers, then try deleting the image. What happens?**

---

### Question 4.2: Container Independence

**Experiment:**
1. Run 3 nginx containers from the same image
2. Exec into container 1 and create `/tmp/file1.txt`
3. Exec into container 2 and create `/tmp/file2.txt`
4. Exec into container 3 and check what files exist in `/tmp/`

**Question:** Can container 3 see file1.txt and file2.txt? Why or why not?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**💡 What does this tell you about container isolation?**

---

### Question 4.3: Image Immutability

**Experiment:**
1. Run nginx
2. Exec in and modify `/usr/share/nginx/html/index.html`
3. Stop and remove the container
4. Run a new nginx container
5. Check if your modifications are still there

**Question:** Are your changes in the new container? What happened to them?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**How would you make permanent changes to an image?**

---

## Part 5: Real-World Debugging Scenario

### Question 5.1: The Crashing Container

**Scenario:** You deployed a container in production. It crashes every 30 seconds (exits with code 1). You need to debug it, but it keeps restarting before you can exec in.

**Experiment:**
Simulate this with:
```bash
docker run -d --name broken --restart always nginx /bin/false
```

Watch it crash and restart. Now try to exec into it.

**Question:** How do you keep it alive long enough to investigate? (Try at least 2 different approaches)

**Commands I tried:**
```bash
# Your experiments here
```

**My solution(s):**

**💡 Which approach would you use in production and why?**

---

### Question 5.2: Container Resource Detective

**Experiment:**
1. Run an nginx container
2. Use `docker stats` to see its resource usage
3. Use `docker inspect` to see its configuration

**Questions:**
- How much memory is it using right now?
- What's its IP address?
- What ports are exposed?
- What's its restart policy?

**Commands I ran:**
```bash
# Your commands here
```

**My answers:**

---

## Part 6: Lifecycle Troubleshooting

### Question 6.1: Port Already in Use

**Experiment:**
1. Start nginx on port 8080
2. Try to start another nginx on port 8080

**Question:** What error do you get? How would you find what's using port 8080 if you didn't know?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

**How to fix it:**

---

### Question 6.2: Container Name Conflicts

**Experiment:**
1. Run a container named "test"
2. Stop it (don't remove)
3. Try to run another container named "test"

**Question:** What happens? How do you fix it?

**Commands I ran:**
```bash
# Your commands here
```

**My answer:**

---

### Question 6.3: Finding Lost Containers

**Scenario:** You ran several containers yesterday during testing. Some are stopped, some are running. You can't remember their names.

**Questions:**
- How do you find ALL containers (running and stopped)?
- How do you find just the stopped ones?
- How do you remove all stopped containers at once?

**Commands I ran:**
```bash
# Your commands here
```

**My answers:**

---

## Final Reflection

### What surprised you most about container lifecycle?

**My answer:**

---

### What's one thing you'll do differently now when working with containers?

**My answer:**

---

### If you had to explain the difference between an image and a container to someone new, how would you explain it?

**My answer:**

---

## Cleanup

Before submitting, clean up your test containers:

```bash
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker system prune -f
```

## Submission

Save this file as `YOURNAME-lifecycle-investigation.md` and submit according to your instructor's directions.

---

## Bonus Challenges (Optional)

If you finish early:

1. **The Zombie Hunter:** What's the difference between `docker ps` and `docker ps -a`? Why would stopped containers stick around?

2. **The Network Detective:** Two containers running on the same host. Can they talk to each other? How?

3. **The Volume Mystery:** Create a container with `-v /data`. Put a file in /data. Remove the container. Where did the file go?
