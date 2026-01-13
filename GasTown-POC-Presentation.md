theme: Ostrich, 1
footer: Gas Town - Multi-Agent Workspace Management
slidenumbers: true

# Gas Town
## Forking & POC-ing Apps with Multi-Agent Coordination

---

# The Problem

- You have multiple projects
- You want to experiment / fork / POC
- Changes span multiple files, need testing
- Context switching is expensive
- "I'll fix it later" becomes technical debt

^We've all been there. You're working on one thing, notice a bug in another project, and either context-switch (expensive) or add it to a list that grows forever.

---

# Enter Gas Town

A **multi-agent workspace manager** that coordinates work across projects

```
Town (~/gt)
├── mayor/          ← Global coordinator (you/AI)
├── llmbrandchecker/
│   ├── polecats/   ← Worker agents
│   ├── refinery/   ← Merge queue
│   └── witness/    ← Lifecycle manager
└── localwardleymaps/
    └── ...
```

^Gas Town is like a small town where different agents have different roles. The Mayor coordinates, Polecats do the work, Refineries handle merging.

---

# The Steam Engine Principle

> "When an agent finds work on their hook, they EXECUTE."

- No confirmation dialogs
- No "should I proceed?"
- Hook = Assignment = DO IT NOW

^This is the core philosophy. The system's throughput depends on agents executing when they find work. No waiting, no asking.

---

# Real Session: Two Bugs Appear

**Bug 1: llmbrandchecker**
```
error: unknown option '--system'
```

**Bug 2: localwardleymaps**
```
Type error: All declarations of 'createWritable'
must have identical modifiers.
```

^This actually happened. Two different projects, two different bugs, surfaced at the same time.

---

# Step 1: Create Beads

```bash
bd create --title="Fix: Invalid --system flag" \
          --type=bug --priority=1
# ✓ Created issue: ll-3f2

bd create --title="Fix: TypeScript createWritable" \
          --type=bug --priority=1
# ✓ Created issue: lo-727
```

**Beads** = persistent issue tracking that survives sessions

^Beads are like tickets but built for agent workflows. They track work across sessions and agents.

---

# Step 2: Dispatch to Polecats

```bash
gt sling ll-3f2 llmbrandchecker
# ✓ Polecat furiosa spawned
# → Created convoy 🚚 hq-cv-mczgy

gt sling lo-727 localwardleymaps
# ✓ Polecat cheedo spawned
# → Created convoy 🚚 hq-cv-ugltk
```

Two workers, working in parallel, on different projects.

^One command spawns a worker with its own git worktree, hooks the work, and starts it running. Completely parallel.

---

# Convoy Dashboard

```bash
gt convoy list

🚚 hq-cv-mczgy: Fix: Invalid --system flag ●
🚚 hq-cv-ugltk: Fix: TypeScript error ●
```

Track all active work at a glance.

^Convoys group related work. You can see status of everything in one command.

---

# Plot Twist: Polecat Can't Find File

```
From: localwardleymaps/cheedo
Subject: lo-727 closed as invalid

File useFileMonitor.ts does not exist in this codebase.
```

**Why?** Polecats spawn from upstream. Local changes weren't pushed.

^This is real. The polecat checked the upstream branch where the file didn't exist yet. It's working as designed - polecats are isolated.

---

# The Fix: Direct Intervention

When automation fails, **the Mayor steps in**:

```bash
# Fix directly in crew workspace
vim crew/localizers/frontend/src/hooks/useFileMonitor.ts

# Remove the optional modifier
- createWritable?: () => Promise<...>
+ createWritable(): Promise<...>

git commit -m "Fix TypeScript modifier conflict"
```

^Sometimes you need to fix things directly. Gas Town doesn't force everything through automation.

---

# Second Plot Twist: Build Still Fails

```
ModuleNotFoundError: No module named 'distutils'
```

Python 3.12+ removed `distutils`. Environment issue.

^Another real problem. The TypeScript was fixed but the build environment was broken.

---

# Solution: Makefile

```makefile
build: venv
    @. $(VENV_DIR)/bin/activate && \
        . ~/.nvm/nvm.sh && \
        nvm use 22 && \
        cd frontend && \
        yarn electron:build

venv:
    python3 -m venv $(VENV_DIR)
    $(VENV_DIR)/bin/pip install setuptools
```

One command: `make build`

^Created a Makefile that handles the Python virtualenv setup automatically.

---

# Third Bug: Claude CLI Hangs

```javascript
// This hangs:
spawn('claude', ['-p', prompt])

// This works:
spawn('claude', ['--print'])
claude.stdin.write(prompt)
claude.stdin.end()
```

Discovered by testing locally before committing.

^The llmbrandchecker app was calling Claude CLI wrong. The fix was to pipe via stdin instead of passing as argument.

---

# Gas Town Architecture

| Component | Role |
|-----------|------|
| **Mayor** | Global coordinator |
| **Polecat** | Worker with git worktree |
| **Witness** | Per-rig lifecycle manager |
| **Refinery** | Merge queue processor |
| **Beads** | Issue tracking system |
| **Convoy** | Work batch tracker |

^Each component has a specific role. They communicate via mail and hooks.

---

# Key Commands

```bash
# Check work
gt hook              # What's on my hook?
gt mail inbox        # Any messages?

# Dispatch work
gt sling <bead> <rig>  # Send work to polecat

# Monitor
gt convoy list       # Active work dashboard
gt status            # Town overview

# Track issues
bd create --title="..." --type=bug
bd ready             # What's unblocked?
bd close <id>        # Mark complete
```

---

# The Capability Ledger

> "Every completion is recorded. Every handoff is logged."

- Your work history is your reputation
- Quality accumulates over time
- Mistakes are recoverable through consistent good work

^This is about building trust through demonstrated capability. The system tracks what actually got done.

---

# When to Use Gas Town

✅ **Good for:**
- Multi-project workspaces
- Parallel bug fixes
- POC/forking experiments
- Agent-assisted development

❌ **Not for:**
- Single-file changes
- Quick scripts
- Projects that don't need isolation

^Gas Town adds overhead. Use it when the coordination benefits outweigh the cost.

---

# Lessons from This Session

1. **Polecats work from upstream** - push local changes first
2. **Environment matters** - Python/Node versions break builds
3. **Test locally** - before committing fixes
4. **Direct intervention is OK** - automation isn't everything
5. **Makefile is your friend** - reproducible builds

^These are the real lessons from the session you just witnessed.

---

# Demo Time

```bash
# Start fresh
gt prime

# Check status
gt status

# See what's ready to work
bd ready

# Dispatch work
gt sling <issue> <rig>

# Monitor progress
gt convoy list
```

^Let's see it in action.

---

# Questions?

**Resources:**
- Gas Town: `~/gt/`
- Beads docs: `bd --help`
- This deck: `localwardleymaps/crew/localizers/`

---

# Thank You

> "Steam engines don't run on politeness -
> they run on pistons firing."

**Gas Town** - Where agents get things done.
