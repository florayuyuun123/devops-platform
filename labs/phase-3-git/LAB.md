# Git Version Control & GitHub Flow

In DevOps, we treat everything as code—even our servers. If it's not in Git, it doesn't exist. Git is your "Save Game" button and your "Undo" button for your entire career.

---

## Task 1 — Configuring Your Identity

### The Concept (What)
We tell Git who we are using `git config`.

### Real-world Context (Why)
When something breaks in production at 3:00 AM, the `git blame` command tells the team exactly who wrote that line of code. If your name isn't on it, they can't call you for help!

### Execution (How)
Configure your global identity on this machine.

```bash
git config --global user.name "Your Name"
```

```bash
git config --global user.email "you@example.com"
```

```bash
git config --global init.defaultBranch main
```

---

## Task 2 — Creating Your First Repository

### The Concept (What)
A "Repository" (or Repo) is a folder that Git is watching. We use `git init` to start watching and `git commit` to save a snapshot.

### Real-world Context (Why)
If you make a mistake today, you can use Git to travel back in time to yesterday's perfect version. This is how we safely update apps used by millions of people.

### Execution (How)
Initialize a new project and make your first commit.

```bash
mkdir my-app && cd my-app
```

```bash
git init
```

```bash
echo "# My App" > README.md
```

```bash
echo "PORT=8080" > .env
```

```bash
echo ".env" > .gitignore
```
*Note: We add `.env` to `.gitignore` so we NEVER accidentally share our private keys or passwords on the internet.*

```bash
git add README.md .gitignore
```

```bash
git commit -m "Initial commit"
```

---

## Task 3 — Branching (The Daily Workflow)

### The Concept (What)
A "Branch" is a parallel version of your code. You work on a branch so you don't break the "Main" version that customers are using.

### Real-world Context (Why)
At a job, you *never* work directly on `main`. You create a branch (like `feature/add-login`), finish your work, and then merge it back once it's tested.

### Execution (How)
Create a new feature branch and merge it.

```bash
git checkout -b feature/add-config
```

```bash
echo "DEBUG=false" >> README.md
```

```bash
git add .
```

```bash
git commit -m "Add debug config"
```

```bash
git checkout main
```

```bash
git merge feature/add-config
```

---

## Task 4 — Undoing Mistakes

### The Concept (What)
Using `git reset` and `git checkout` to throw away bad code you haven't committed yet.

### Real-world Context (Why)
Everyone makes mistakes. If you accidentally delete a critical file or break a configuration, Git can restore it instantly.

### Execution (How)
Create a "mistake" and undo it.

```bash
echo "oops" > mistake.txt
```

```bash
git add mistake.txt
```

```bash
git reset HEAD mistake.txt
```

```bash
git checkout -- mistake.txt 2>/dev/null || true
```

---

## Task 5 — Reading History

### The Concept (What)
Using `git log` and `git diff` to see what happened in the past.

### Real-world Context (Why)
If a server starts crashing today, you check `git log` to see exactly what changed in the last 24 hours. Most bugs are caused by recent changes!

### Execution (How)
Inspect your project's history.

```bash
git log --oneline --graph --all
```

```bash
git diff HEAD~1 HEAD
```

---

## Challenge
Create a branch called `fix/typo`, make a small change to `README.md`, commit it, then merge it back into `main` and delete the branch. Use `git log --oneline --graph` to see your beautiful merge history.
