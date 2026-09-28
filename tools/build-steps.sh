#!/usr/bin/env bash
# Rebuilds the step-NN-* tags from the current contents of main.
#
# Each step checks out the finished tree, removes the files that step has not
# introduced yet, copies in that step's versions from tools/steps/NN/, and
# commits. Run it after changing anything on main so the tags stay in sync.
#
#   ./tools/build-steps.sh
#
# Existing step tags are deleted and recreated. Nothing else is touched.
set -euo pipefail
cd "$(dirname "$0")/.."

FINAL="$(git rev-parse HEAD)"
git diff --quiet || { echo "Working tree is dirty. Commit or stash first."; exit 1; }

for t in $(git tag -l 'step-*'); do git tag -d "$t" >/dev/null; done
git checkout -q --orphan build-steps-tmp
git rm -rq --cached . >/dev/null

commit () { git add -A; git commit -qm "$2"; git tag "$1"; echo "  $1"; }
# Start each step from exactly the finished tree: clear everything tracked
# (ignored files such as node_modules and .env.local are left alone), then
# check out main's files.
restore () { git rm -rq --cached . >/dev/null 2>&1 || true; git clean -fdq; git checkout -q "$FINAL" -- .; }
variant () { cp -R "tools/steps/$1/." .; }

echo "Building steps:"


# --- 0: the Lab 05 dashboard on the example_06 server, with deleteEvent ---
restore
rm -f \
   server/src/auth.ts \
   web/src/auth/auth_service.ts \
   web/src/auth/fake_auth_service.ts \
   web/src/auth/firebase_auth_service.ts \
   web/src/data/kai_api_service.test.ts \
   web/src/features/auth/AccountBar.tsx \
   web/src/features/auth/FirebaseSetupNeeded.tsx \
   web/src/features/auth/NotOrganiserScreen.tsx \
   web/src/features/auth/OrganiserGate.test.tsx \
   web/src/features/auth/SignIn.test.tsx \
   web/src/features/auth/SignInScreen.tsx \
   web/src/features/auth/TokenPeek.tsx \
   web/src/features/feed/Ownership.test.tsx \
   web/src/state/AuthContext.tsx
variant 00
commit step-00-start "Step 0: the Lab 05 dashboard on the example_06 server, with deleteEvent"

# --- 1: Google sign-in on the dashboard ---------------------
restore
rm -f \
   server/src/auth.ts \
   web/src/data/kai_api_service.test.ts \
   web/src/features/auth/NotOrganiserScreen.tsx \
   web/src/features/auth/OrganiserGate.test.tsx \
   web/src/features/feed/Ownership.test.tsx \
   web/src/state/OrganiserContext.tsx
variant 01
commit step-01-sign-in "Step 1: Google sign-in on the dashboard"

# --- 2: the server verifies the ID token, and postedById leaves the schema ---
restore
rm -f \
   web/src/features/auth/NotOrganiserScreen.tsx \
   web/src/features/auth/OrganiserGate.test.tsx \
   web/src/features/feed/Ownership.test.tsx \
   web/src/state/OrganiserContext.tsx
variant 02
commit step-02-verify "Step 2: the server verifies the ID token, and postedById leaves the schema"

# --- 3: organisers collection and the me query --------------
restore
rm -f \
   web/src/features/feed/Ownership.test.tsx
variant 03
commit step-03-organisers "Step 3: organisers collection and the me query"

# --- 4: only the organiser who posted an event can delete it ---
restore
variant 04
commit step-04-ownership "Step 4: only the organiser who posted an event can delete it"

# --- 5: Firestore rules -------------------------------------------------------
restore
commit step-05-rules "Step 5: Firestore rules deny everything except public event reads"

git checkout -q main
git branch -qD build-steps-tmp
echo "Done. ./demo.sh list to see them."
