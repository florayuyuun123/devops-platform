# Git version control & GitHub flow

## Why this matters
Every company uses Git. You will use it every single day as a DevOps engineer.

---

## Task 1 — Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --list
```

## Task 2 — Create a repository
```bash
mkdir my-app && cd my-app
git init
echo "# My App" > README.md
echo "PORT=8080" > .env
echo ".env" > .gitignore     # never commit secrets
git status
git add README.md .gitignore
git commit -m "Initial commit"
git log --oneline
```

## Task 3 — Branching (the daily workflow)
```bash
git checkout -b feature/add-config    # create and switch to new branch
echo "DEBUG=false" >> README.md
git add .
git commit -m "Add debug config"
git checkout main                     # go back to main
git merge feature/add-config          # merge the feature in
git branch -d feature/add-config      # clean up
git log --oneline --graph
```

## Task 4 — Undo mistakes
```bash
echo "oops" > mistake.txt
git add mistake.txt
git reset HEAD mistake.txt            # unstage the file
git checkout -- mistake.txt 2>/dev/null || true  # discard changes
git stash                             # temporarily save work
git stash pop                         # restore saved work
```

## Task 5 — Read history
```bash
git log --oneline --graph --all
git diff HEAD~1 HEAD                  # what changed in last commit
git blame README.md                   # who changed each line
```

## Challenge
Create a branch called `fix/typo`, make a change, commit it,
then merge it back into `main` and delete the branch.
Paste your `git log --oneline --graph` output somewhere.
