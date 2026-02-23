![Lab 2 hero image](../../../assets/generated/week-01-lab-02/hero.png)

# Lab 2: Build Your Python App Container

**Time:** 40 minutes  
**Objective:** Write a Dockerfile from scratch and build a containerized Python application

---

## The Application

We have a simple Python web application that responds with a greeting. You'll:

1. Examine the application code
2. Write a Dockerfile to containerize it
3. Build and run the container
4. Customize the app and rebuild

---

## Part 1: Explore the Application

Look at the starter application:

```bash
cd week-01/labs/lab-02-python-app/starter
ls -la
```

You'll see:
- `app.py` - The main application
- `requirements.txt` - Python dependencies

### Examine app.py

```bash
cat app.py
```

```python
from flask import Flask
import os
import socket

app = Flask(__name__)

# Configurable via environment variable
GREETING = os.environ.get("GREETING", "Hello")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "development")

@app.route("/")
def home():
    hostname = socket.gethostname()
    return f"""
    <h1>{GREETING} from Container Land!</h1>
    <p><strong>Environment:</strong> {ENVIRONMENT}</p>
    <p><strong>Hostname:</strong> {hostname}</p>
    <p><strong>Python path:</strong> {os.sys.executable}</p>
    """

@app.route("/health")
def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
```

This is a Flask web app that:
- Shows a greeting on the home page
- Reads configuration from environment variables
- Has a health check endpoint
- Runs on port 5000 by default

### Examine requirements.txt

```bash
cat requirements.txt
```

```
flask==3.0.0
```

One dependency: Flask.

---

## Part 2: Write Your Dockerfile

Create a new file called `Dockerfile` (no extension) in the `starter` directory:

```bash
touch Dockerfile
```

Now open it in your editor and build it step by step.

### Step 1: Choose a Base Image

Every Dockerfile starts with `FROM`. We need Python:

```dockerfile
FROM python:3.11-slim
```

> **Why `3.11-slim`?** 
> - `3.11` - Matches the Python version we want
> - `slim` - Debian-based but without extras we don't need (~150MB vs ~900MB for full image)

### Step 2: Set a Working Directory

```dockerfile
FROM python:3.11-slim

WORKDIR /app
```

`WORKDIR` creates the directory and sets it as the current directory for subsequent commands. Think of it like `mkdir -p /app && cd /app`.

### Step 3: Copy Dependencies First

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

> **Why copy requirements.txt separately?** This is a caching optimization. Docker caches each layer. If `requirements.txt` hasn't changed, Docker reuses the cached layer and skips `pip install`. We'll explore this more in Week 2.

### Step 4: Copy Application Code

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
```

### Step 5: Document the Port

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000
```

`EXPOSE` doesn't actually publish the port—it's documentation. It tells people reading the Dockerfile (and tools like Docker Compose) which ports the application uses.

### Step 6: Define the Startup Command

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

`CMD` defines the default command to run when the container starts.

### Complete Dockerfile

Your final `Dockerfile` should look like this:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

---

## Part 3: Build the Image

From the `starter` directory (where the Dockerfile is):

```bash
docker build -t my-python-app:v1 .
```

Breaking this down:
- `docker build` - Build an image from a Dockerfile
- `-t my-python-app:v1` - Tag it with name `my-python-app` and version `v1`
- `.` - Build context is current directory

Watch the output! You'll see each layer being created:
```
Step 1/7 : FROM python:3.11-slim
Step 2/7 : WORKDIR /app
Step 3/7 : COPY requirements.txt .
...
```

### Verify Your Image

```bash
docker images | grep my-python-app
```

You should see your image with the `v1` tag.

---

## Part 4: Run Your Container

```bash
docker run -d --name myapp -p 5000:5000 my-python-app:v1
```

### Test It

```bash
curl localhost:5000
```

**In Codespaces:** Click the "Ports" tab and open port 5000.

You should see:
```html
<h1>Hello from Container Land!</h1>
<p><strong>Environment:</strong> development</p>
<p><strong>Hostname:</strong> abc123def456</p>
...
```

The hostname is the container ID!

### Check the Health Endpoint

```bash
curl localhost:5000/health
```

```json
{"status": "healthy"}
```

---

## Part 5: Customize with Environment Variables

Remember the `GREETING` and `ENVIRONMENT` variables in the code? Let's override them:

```bash
# Stop the current container
docker rm -f myapp

# Run with custom environment variables
docker run -d --name myapp \
    -p 5000:5000 \
    -e GREETING="Welcome" \
    -e ENVIRONMENT="production" \
    my-python-app:v1

curl localhost:5000
```

Now it shows "Welcome from Container Land!" and "Environment: production".

---

## Part 6: Add Your Student Information (REQUIRED)

**⚠️ IMPORTANT: This section is required for assignment submission!**

You must modify the application to include your name. This will be used to verify your submission when we deploy all student containers.

### Step 1: Update app.py with Your Name

Edit `app.py` to include your name as an environment variable. Add this near the top with the other environment variables:

```python
# Configurable via environment variable
GREETING = os.environ.get("GREETING", "Hello")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "development")
STUDENT_NAME = os.environ.get("STUDENT_NAME", "YOUR_NAME_HERE")  # <-- Replace with your actual name!
```

Then update the home route to display it:

```python
@app.route("/")
def home():
    hostname = socket.gethostname()
    return f"""
    <h1>{GREETING} from Container Land!</h1>
    <p><strong>Student:</strong> {STUDENT_NAME}</p>
    <p><strong>Environment:</strong> {ENVIRONMENT}</p>
    <p><strong>Hostname:</strong> {hostname}</p>
    <p><strong>Python path:</strong> {os.sys.executable}</p>
    """
```

### Step 2: Add a Student Info Endpoint

Add a new `/student` endpoint that returns JSON with your information:

```python
@app.route("/student")
def student():
    return {
        "name": STUDENT_NAME,
        "github_username": "YOUR_GITHUB_USERNAME",  # Replace with your GitHub username
        "container_tag": "v2-student"
    }
```

### Step 3: Rebuild and Test

```bash
# Build with student tag
docker build -t my-python-app:v2-student .

# Stop any running containers
docker rm -f myapp

# Run with your name
docker run -d --name myapp \
    -p 5000:5000 \
    -e STUDENT_NAME="Your Actual Name" \
    my-python-app:v2-student

# Test the main page
curl localhost:5000

# Test the student endpoint
curl localhost:5000/student
```

You should see your name displayed on the main page and in the JSON response.

### Step 4: Verify Requirements

✅ **Checklist before proceeding:**
- [ ] Your name appears in the app (not "YOUR_NAME_HERE")
- [ ] The `/student` endpoint returns your GitHub username
- [ ] The container runs successfully with your modifications
- [ ] You've tested both endpoints

**Note:** Keep this container image! You'll push it to your GitHub Container Registry in Lab 3.

---

## Part 7: Additional Challenges (Optional)

### Challenge 1: Add More Endpoints

Add a `/info` endpoint that returns additional information:

```python
@app.route("/info")
def info():
    return {
        "app": "my-python-app",
        "version": "v2-student",
        "author": STUDENT_NAME,
        "features": ["health-check", "student-info", "environment-config"]
    }
```

Rebuild as `v3-student` and test:

```bash
docker build -t my-python-app:v3-student .
docker rm -f myapp
docker run -d --name myapp -p 5000:5000 my-python-app:v3-student
curl localhost:5000/info
```

### Challenge 2: Experiment with the Base Image

Try changing `FROM python:3.11-slim` to `FROM python:3.11-alpine` and rebuild.

Questions to answer:
1. Did it work? If not, what error did you get?
2. How much smaller is the alpine-based image? (`docker images`)
3. What's different about Alpine that might cause issues?

> **Hint:** Alpine uses `musl libc` instead of `glibc`. Some Python packages with C extensions may need extra work.

---

## Part 8: View Your Image Layers

See how your image is structured:

```bash
docker history my-python-app:v2-student
```

Each line is a layer. Notice how each Dockerfile instruction created a layer?

---

## Checkpoint ✅

Before moving on, verify you can:

- [ ] Write a Dockerfile from scratch
- [ ] Build an image with `docker build -t name:tag .`
- [ ] Run a container from your image
- [ ] Pass environment variables with `-e`
- [ ] **Your name appears in the application (REQUIRED)**
- [ ] **The `/student` endpoint returns your information (REQUIRED)**
- [ ] Modify code and rebuild with a new tag
- [ ] Explain what each Dockerfile instruction does

---

## Clean Up

```bash
docker rm -f myapp
```

Keep your images—we'll push them to a registry in Lab 3!

---

## Demo

![Docker Build Demo](../../../assets/generated/week-01-lab-02/demo.gif)

---

## Next Lab

Continue to [Lab 3: Push to Registries](../lab-03-registries/)
