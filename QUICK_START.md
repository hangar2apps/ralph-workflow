# Ralph Workflow - Quick Steps

## Setup (one time)

1. `ln -s ~/Documents/Hangar2Apps-Github/ralph-workflow ~/ralph-workflow`
2. Make sure Signal API is running: `docker ps | grep signal`

## For each feature

1. Create worktree: `cd ~/path/to/project && git worktree add ~/worktrees/ProjectName/feature -b feature/feature-name`
            ie: cd ~/Documents/Hangar2Apps-Github/ScooperHero-Landing
            ie: git worktree add ~/worktrees/ScooperHero-Landing/admin-dashboard -b feature/admin-dashboard

2. Go there: `cd ~/worktrees/ProjectName/feature`
            ie: cd ~/worktrees/ScooperHero-Landing/admin-dashboard

3. Create PRD: `claude` → "Create a PRD for [feature]. Save PRD.md and progress.txt in the current directory."
    - have Claude Desktop help with this.

4. Run Ralph: `~/ralph-workflow/ralph.sh 20`

## When done

1. Test in worktree directory
2. cd into git repo `cd ~/Documents/Hangar2Apps-Github/ScooperHero`

3. Review: `git log --oneline && git diff <branch>`

4. Merge: `git merge feature/<feature-name>`
            ie: `git merge feature/rating`

5. Clean up: `git worktree remove ~/worktrees/<ProjectName>/<feature>`
           ie: - `git worktree remove ~/worktrees/ScooperHero/ratings`

6. Delete worktree `git branch -d feature/feature-name`
            ie - `git branch -d feature/ratings`