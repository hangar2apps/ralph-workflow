# Ralph Workflow Usage Guide

## Overview

Ralph is a bash loop that runs Claude Code repeatedly, with a fresh context each iteration. Claude works through a PRD (Product Requirements Document) one task at a time until everything is complete.

```
┌─────────────────────────────────────────────────────────┐
│  ralph.sh                                               │
│                                                         │
│  for each iteration:                                    │
│    1. Fresh Claude instance starts                      │
│    2. Reads PRD.md (what to do)                        │
│    3. Reads progress.txt (what was learned)            │
│    4. Does ONE task                                     │
│    5. Commits, updates PRD, logs progress              │
│    6. Exits → next iteration with fresh context        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## One-Time Setup

### 1. Configure environment

```bash
cd ~/ralph-workflow
cp .env.example .env
nano .env
```

Set your Signal numbers:
```
SIGNAL_API_URL=http://localhost:9924
SIGNAL_BOT_NUMBER=+1XXXXXXXXXX
SIGNAL_USER_NUMBER=+1XXXXXXXXXX
```

### 2. Create symlink (optional, for easier access)
```bash
ln -s ~/Documents/Hangar2Apps-Github/ralph-workflow ~/ralph-workflow
```

### 3. Ensure Signal API is running

```bash
docker ps | grep signal
```

If not running:
```bash
cd ~/ralph-workflow
docker-compose up -d
```

---

## Starting a Feature

### Step 1: Create a worktree

```bash
cd ~/Documents/Hangar2Apps-Github/ScooperHero  # or your project
git worktree add ~/worktrees/ScooperHero/ratings -b feature/ratings
```

If branch already exists:
```bash
git worktree add ~/worktrees/ScooperHero/ratings ratings
```

### Step 2: Go to the worktree

```bash
cd ~/worktrees/ScooperHero/ratings
```

### Step 3: Create the PRD

Start Claude and use the PRD skill:

```bash
claude
```

Then tell Claude:
```
Create a PRD for: [describe your feature]
```

Claude will:
1. Ask clarifying questions (answer with "1A, 2B, 3C" format)
2. Generate `PRD.md` with properly sized user stories
3. Create empty `progress.txt`

Review the PRD before continuing:
```bash
cat PRD.md
```

### Step 4: Run Ralph

```bash
~/ralph-workflow/ralph.sh 20
```

The number is max iterations (default 10). Each iteration:
- Fresh context (no memory bloat)
- Does ONE task from PRD
- Commits when done
- Logs learnings to progress.txt
- Sends Signal messages

### Step 5: Monitor

Watch the terminal output, or check your Signal for messages:
- "Starting iteration - working on US-001"
- "Stuck on [problem] - need help"
- "All tasks complete!"

---

## While Running

### If Claude gets stuck

Reply via Signal with guidance. Claude will see it next iteration via progress.txt learnings.

Or stop Ralph (Ctrl+C), manually edit progress.txt with hints, restart.

### If you need to pause

Press `Ctrl+C` to stop. Progress is saved in:
- `PRD.md` - completed tasks marked [x]
- `progress.txt` - learnings from each iteration
- Git commits - one per completed task

Resume anytime:
```bash
~/ralph-workflow/ralph.sh 20
```

---

## When Complete

### 1. Review the work

```bash
cd ~/worktrees/ScooperHero/ratings

# See commits
git log --oneline

# See all changes
git diff main

# Check the code
code .
```

### 2. Merge if happy

```bash
cd ~/Documents/Hangar2Apps-Github/ScooperHero
git merge feature/ratings
git push
```

### 3. Clean up

```bash
git worktree remove ~/worktrees/ScooperHero/ratings
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Create worktree | `git worktree add ~/worktrees/PROJECT/FEATURE -b feature/FEATURE` |
| Go to worktree | `cd ~/worktrees/PROJECT/FEATURE` |
| Create PRD | `claude` then "Create a PRD for: [feature]" |
| Run Ralph | `~/ralph-workflow/ralph.sh 20` |
| Stop Ralph | `Ctrl+C` |
| Check progress | `cat PRD.md` or `cat progress.txt` |
| Merge when done | `cd ~/original/repo && git merge feature/FEATURE` |
| Clean up | `git worktree remove ~/worktrees/PROJECT/FEATURE` |

---

## PRD Tips

### Right-sized tasks (ONE context window each):
- Add a database column
- Add a single UI component
- Update one server action
- Add a filter dropdown

### Too big (split these):
- "Build the dashboard" → schema, queries, UI, filters
- "Add authentication" → schema, middleware, login UI, session
- "Add drag and drop" → drag events, drop zones, state, persistence

### Good acceptance criteria:
- "Add `status` column with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Typecheck passes"

### Bad acceptance criteria:
- "Works correctly"
- "Good UX"
- "Handles edge cases"

---

## Troubleshooting

### Claude not finding PRD.md

Make sure you're in the worktree directory:
```bash
pwd  # should be ~/worktrees/PROJECT/FEATURE
ls   # should see PRD.md
```

### Signal messages not sending

Check Signal API:
```bash
curl http://localhost:9924/v1/about
```

### Context getting too big

Your tasks are too large. Edit PRD.md and split into smaller stories.

### Ralph keeps failing on same task

Check progress.txt for error patterns. Add hints manually:
```bash
echo "## Hint: The API endpoint is /api/v2/tasks not /api/tasks" >> progress.txt
```

### Need to restart fresh

```bash
# Reset PRD checkboxes
sed -i '' 's/\[x\]/[ ]/g' PRD.md

# Clear progress
echo "# Progress Log\n\n## Learnings\n\n---" > progress.txt

# Restart
~/ralph-workflow/ralph.sh 20
```

