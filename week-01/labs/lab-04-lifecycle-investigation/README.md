# Lab 3: Container Lifecycle Investigation

**Type:** Independent exploration  
**Time:** 30-45 minutes  
**Deliverable:** Completed worksheet

---

## Purpose

You've run containers in Labs 1 and 2. Now it's time to **really** understand how they work.

This lab reinforces container fundamentals through hands-on discovery. No copying from Stack Overflow - you'll learn by experimenting and observing.

---

## What You'll Learn

By completing this investigation, you'll understand:
- **Container states:** created, running, paused, stopped, exited
- **Lifecycle commands:** start, stop, restart, pause, kill, rm
- **Data persistence:** what survives container removal, what doesn't
- **Image vs Container:** the critical distinction that confuses everyone
- **Debugging techniques:** how to investigate crashed or misbehaving containers
- **Common pitfalls:** port conflicts, name collisions, and how to fix them

---

## Instructions for Students

### 1. Download the Worksheet

Get [`WORKSHEET.md`](./WORKSHEET.md) and save it as `YOURNAME-lifecycle-investigation.md`

### 2. Complete Each Section

Work through the questions **by running commands and observing results**. 

**Rules:**
- Answer in your own words (no copy-paste from docs)
- Include the commands you ran to discover each answer
- Mark surprising discoveries with 💡
- It's okay to be wrong - the learning is in figuring out why!

### 3. Clean Up After Each Section

Don't let containers accumulate. Use:
```bash
docker rm -f $(docker ps -aq) 2>/dev/null || true
```

### 4. Submit Your Completed Worksheet

Save your completed worksheet and submit according to your instructor's directions.

---

## Expected Time Breakdown

| Section | Time |
|---------|------|
| Part 1: Container States | 5-10 min |
| Part 2: Data Lifecycle | 5-10 min |
| Part 3: Lifecycle Commands | 5 min |
| Part 4: Image-Container Relationship | 10 min |
| Part 5: Real-World Debugging | 5-10 min |
| Part 6: Troubleshooting | 5 min |
| **Total** | **30-45 min** |

---

## Tips for Success

### Don't Just Read - Experiment!

❌ **Bad approach:**
1. Read the question
2. Google the answer
3. Write it down

✅ **Good approach:**
1. Read the question
2. Form a hypothesis ("I think X will happen because...")
3. Run commands to test it
4. Observe what actually happens
5. Explain the result in your own words

### Use `--help` Liberally

```bash
docker --help
docker ps --help
docker run --help
docker inspect --help
```

The documentation is built-in!

### Try Things That Might "Break"

You're in a safe environment. The worst that happens is:
```bash
docker rm -f $(docker ps -aq)  # Delete all containers
docker system prune -f         # Clean up
```

Then start fresh. **Breaking things teaches you how they work.**

### Keep a Terminal Log

Consider using `script` to record your session:
```bash
script ~/lifecycle-investigation.log
# Do your work
# Ctrl+D to stop recording
```

This captures everything you tried - useful for reflection!

---

## Common Questions

### "How do I know if my answer is right?"

If your commands demonstrate the concept and your reasoning makes sense, you're on the right track. There's often more than one way to discover the same truth.

### "Can I work with a partner?"

You can discuss approaches, but each person must run the commands and write answers in their own words.

### "What if I get stuck?"

1. Try `--help` on the command
2. Try variations and see what happens
3. Check `docker ps -a` to see container states
4. Use `docker inspect` to see details
5. Ask in the class forum with what you've tried

### "This is taking longer than 45 minutes!"

That's okay. This is exploration, not a race. The goal is deep understanding, not speed.

---

## Assessment

Your submission will be evaluated on:
- **Experimentation evidence:** Did you actually run commands?
- **Understanding:** Can you explain concepts in your own words?
- **Insight:** Did you discover the "why" behind the behavior?
- **Completeness:** Did you attempt all sections?

**Not evaluated on:**
- Speed
- Getting every answer "right" on the first try
- Having the same answers as other students

---

## After You Finish

### Reflect on Key Insights

1. What's the #1 thing you learned about containers?
2. What misconception did you have before this lab?
3. How will this knowledge help you in future labs?

### Preview: Why This Matters

**Week 3 (Compose):** You'll run multi-container applications. Understanding lifecycle is crucial when services depend on each other.

**Week 4 (Kubernetes):** K8s manages container lifecycle automatically. Understanding these fundamentals helps you debug pod failures.

**Production:** Knowing the difference between stop/start vs rm/run can mean the difference between preserving logs for debugging and losing them forever.

---

## Files

- `WORKSHEET.md` - The questions you'll answer (download this!)
- `SOLUTION_KEY.md` - Instructor reference with expected answers and teaching notes (don't peek!)
- `README.md` - This file

---

## Need Help?

- **Stuck on a command?** Try `docker COMMAND --help`
- **Container won't behave?** Use `docker inspect` to see its full state
- **Made a mess?** `docker rm -f $(docker ps -aq)` to reset
- **Still stuck?** Post in the class forum with:
  - The question you're on
  - The commands you've tried
  - What you expected vs what happened

---

## Final Cleanup

After completing the worksheet:

```bash
# Remove all containers
docker rm -f $(docker ps -aq)

# Clean up system
docker system prune -f

# Verify
docker ps -a  # Should be empty
```

---

Good luck! Remember: **the learning is in the experimentation, not in getting perfect answers.**

🐳 Happy container exploring! 🐳
