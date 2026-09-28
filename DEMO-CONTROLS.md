# Demo controls — operator guide

This repo uses git tags to organise the steps built in class, driven by
`demo.sh` (macOS/Linux) and `demo.ps1` (Windows). Same system as earlier examples; if you have run those, there is nothing new here.

## The status bar buttons

Opening this folder in VS Code puts six buttons along the bottom: **Prev step**,
**Next step**, **List steps**, **Jump**, **First step** and **main**. They come from
the Task Buttons extension (`spencerwmiles.vscode-task-buttons`), which VS Code
offers to install the first time you open the folder.

If the buttons are missing:

- Install the extension. Cmd/Ctrl+Shift+P, `Extensions: Show Recommended
  Extensions`, and take the workspace recommendation.
- Reload afterwards. Cmd/Ctrl+Shift+P, `Developer: Reload Window`. Tasks are
  read at startup.
- Check the folder you opened is this one rather than a parent. VS Code only
  reads `.vscode/` from the workspace root.

Everything the buttons do is also in `Tasks: Run Task`, and in the terminal
commands below. The buttons are a convenience, not a dependency.

## The short version

```
./demo.sh run             # start the Kai Events server on port 3734
./demo.sh list            # show all steps, marking the current one with *
./demo.sh next            # move forward one step
./demo.sh prev            # move back one step
./demo.sh jump 04         # jump straight to step 4
./demo.sh discard-changes # throw away edits, stay put
./demo.sh reset           # leave the demo, back to main
```

On Windows use `.\demo.ps1` instead. If macOS or Linux says "Permission
denied", run `chmod +x demo.sh` first. If PowerShell blocks the script, run
`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.

## What happens on a step change

`git reset --hard HEAD`, then `git clean -fd`, then `git checkout <tag>`.

Moving between steps **discards any changes you have made**. That is
intentional: every step is a clean starting point.

`git clean -fd` removes untracked files but never ignored ones, so your
`.env.local` survives every step change.

## Nothing needs restarting

`tsx watch` restarts the server when a step change rewrites its files, and Vite
hot-reloads the dashboard. Leave both running for the whole lecture.

Every dependency is declared from the first step, so no step needs a second
`npm install`.

## If the scripts will not run at all

```
git reset --hard HEAD
git clean -fd
git checkout step-02-verify
```

## Running order

Three terminals:

1. `./demo.sh run` — the Kai Events server on 3734
2. `npm --prefix web run dev` — the dashboard on 5734
3. the repo root, for `./attacks.sh`

## Rebuilding the steps

The step tags are built from `main` by `tools/build-steps.sh`, using the files
in `tools/steps/`. After changing anything on `main`, run it again and push
with `git push --force --tags`.
