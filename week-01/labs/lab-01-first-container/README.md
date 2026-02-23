![Lab 1 hero image](../../../assets/generated/week-01-lab-01/hero.png)

# Lab 1: Your First Container

**Time:** 30 minutes  
**Objective:** Pull, run, and explore containers from Docker Hub

---

## Background: What a Container Actually Is

An image is a read-only template, and a container is a running instance of that template with a thin writable layer on top. If you remember one distinction for the entire course, use this one: images are build artifacts, containers are runtime processes. Deleting a container does not delete its image, and creating a new container from the same image starts with a fresh writable layer unless you mount external storage.

`docker run` does two jobs: create and start. It creates container metadata from the image config, then starts the container's main process as PID 1 inside isolated namespaces. A container stays alive only while that PID 1 process is alive, which is why debugging often starts with logs and process state rather than "is Docker up." In this lab, nginx is that long-running process.

Port publishing like `-p 8080:80` is host-to-container network translation, not a change inside nginx itself. Your host listens on port 8080 and forwards traffic into container port 80 where nginx serves requests. That is why two containers cannot both publish the same host port at the same time even if they expose the same internal port.

`docker exec` adds a new process into an already-running container; it does not restart or replace the main process. This is useful because it lets you inspect filesystem, environment, and running processes in place while the application keeps serving traffic. Treat it as live inspection, not lifecycle control.

The lifecycle commands in this lab map to real operational behaviors: stop sends a graceful signal first, kill is immediate, start restarts an existing stopped container, and remove deletes the container metadata plus writable layer. For deeper details, see the official Docker containers documentation: https://docs.docker.com/engine/containers/.

---

## Part 1: Run Your First Container

### Pull and Run nginx

Let's start with a simple web server:

```bash
docker run -d --name my-nginx -p 8080:80 nginx
```

Let's break down this command:
- `docker run` - Create and start a container
- `-d` - Run in detached mode (background)
- `--name my-nginx` - Give it a friendly name
- `-p 8080:80` - Map host port 8080 to container port 80
- `nginx` - The image to run

### Verify It's Running

```bash
docker ps
```

You should see your container listed with status "Up".

### Access the Web Server

**In Codespaces:** Click the "Ports" tab and click the globe icon next to port 8080.

**In a VM:** Open a browser to `http://localhost:8080` or use curl:

```bash
curl localhost:8080
```

You should see the nginx welcome page!

---

## Part 2: Explore the Running Container

### Look Inside with exec

Get a shell inside the running container:

```bash
docker exec -it my-nginx /bin/bash
```

Now you're inside the container! Let's explore:

```bash
# Where are we?
pwd

# What's in here?
ls -la

# Where's the web content?
ls /usr/share/nginx/html

# What's the hostname?
hostname

# What processes are running?
ps aux

# Exit the container shell
exit
```

> **Important Detail:** You just ran a shell (`/bin/bash`) as a NEW process inside the existing container. The nginx process is still running separately.

### View Container Logs

```bash
docker logs my-nginx
```

This shows stdout/stderr from the container. Make a few more requests:

```bash
curl localhost:8080
curl localhost:8080/nonexistent
docker logs my-nginx
```

Notice how each request appears in the logs?

### Inspect Container Details

```bash
docker inspect my-nginx
```

This is a lot of JSON! Let's extract specific info:

```bash
# What's the container's IP address?
docker inspect my-nginx --format '{{.NetworkSettings.IPAddress}}'

# What image is it running?
docker inspect my-nginx --format '{{.Config.Image}}'

# When was it created?
docker inspect my-nginx --format '{{.Created}}'
```

---

## Part 3: Container Lifecycle

### Stop the Container

```bash
docker stop my-nginx
docker ps
```

The container is stopped but still exists:

```bash
docker ps -a
```

### Start It Again

```bash
docker start my-nginx
docker ps
curl localhost:8080
```

It's back! And it remembered its configuration.

### Remove the Container

First stop it, then remove:

```bash
docker stop my-nginx
docker rm my-nginx
```

Or force-remove a running container:

```bash
# Let's create a new one first
docker run -d --name temp-nginx nginx
docker rm -f temp-nginx
```

---

## Part 4: Understanding Port Mapping

Let's experiment with ports:

### Run Multiple Containers

```bash
# First nginx on port 8081
docker run -d --name nginx-1 -p 8081:80 nginx

# Second nginx on port 8082
docker run -d --name nginx-2 -p 8082:80 nginx

# Third nginx on port 8083
docker run -d --name nginx-3 -p 8083:80 nginx

docker ps
```

All three containers are running the same image, but each maps to a different host port.

### Test Each One

```bash
curl localhost:8081
curl localhost:8082
curl localhost:8083
```

### What Happens Without Port Mapping?

```bash
docker run -d --name hidden-nginx nginx
```

Can you access it from the host?

```bash
curl localhost:80  # Doesn't work!
```

The container is running nginx on port 80 *inside* the container, but there's no mapping to the host. You'd need to use the container's IP directly:

```bash
# Get container IP
docker inspect hidden-nginx --format '{{.NetworkSettings.IPAddress}}'
# Let's say it's 172.17.0.5
curl 172.17.0.5:80  # This works from the host (Linux only)
```

> **Note:** In Codespaces/Mac/Windows, you can't reach container IPs directly because Docker runs in a VM. Port mapping (`-p`) is required.

### Clean Up

```bash
docker rm -f nginx-1 nginx-2 nginx-3 hidden-nginx
docker ps -a  # Should be empty now
```

---

## Part 5: Images vs Containers

### List Images

```bash
docker images
```

You should see the nginx image you pulled. Images are the blueprints; containers are running instances.

### Pull Without Running

```bash
docker pull python:3.11-slim
docker images
```

Now you have the Python image but no containers from it yet.

### One Image, Many Containers

```bash
docker run -d --name python-1 python:3.11-slim sleep 3600
docker run -d --name python-2 python:3.11-slim sleep 3600
docker run -d --name python-3 python:3.11-slim sleep 3600

docker ps
```

Three containers from the same image, each isolated from the others.

```bash
# Clean up
docker rm -f python-1 python-2 python-3
```

---

## Checkpoint ✅

Before moving on, verify you can:

- [ ] Run a container with `docker run`
- [ ] List running containers with `docker ps`
- [ ] Execute commands inside a container with `docker exec`
- [ ] View logs with `docker logs`
- [ ] Stop and remove containers
- [ ] Explain what `-p 8080:80` means

---

## Answers to Think About

1. **What's the difference between `docker stop` and `docker rm`?**

2. **If you `docker exec` into a container and run `ps aux`, do you see the host's processes?**

3. **What happens to files you create inside a container when you `docker rm` it?**

4. **Can two containers use the same host port (e.g., both `-p 8080:80`)?**

---

## Demo

![First Container Demo](../../../assets/generated/week-01-lab-01/demo.gif)

---

## Next Lab

Continue to [Lab 2: Build Your Python App](../lab-02-python-app/)
