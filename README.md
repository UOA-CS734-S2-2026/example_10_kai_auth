# Kai Finder, with authentication

The live-coding demo for **COMPSCI 734, Lectures 16 and 17 (Week 09): Authentication and Authorisation**.

Until now the Kai Events server believed whatever the client told it. The
dashboard sent `postedById`, and the server wrote it down. This repo adds the
checks: Google sign-in on the dashboard, token verification on the server, an
organisers collection, an ownership check on delete, and Firestore rules that
deny everything the clients do not need.

| Folder | What it is |
| --- | --- |
| `server/` | The Kai Events server from example_06 (REST + GraphQL over Firestore, FCM), plus `deleteEvent` |
| `web/` | The organiser dashboard from the Lab 05 solution |

Both live in one repo because the steps change them together: the dashboard
starts sending the token in the same step the server starts checking it.

## Built and tested with

```
Node.js v22 or newer
npm 10 or newer
```

| Package | Version |
| --- | --- |
| `firebase` (web) | 12.19.0 |
| `firebase-admin` (server) | 14.2.0 |
| `react` | 18.3.1 |
| `vite` | 5.4.11 |
| `vitest` | 2.1.8 |

## Setup

You need the Firebase project.

1. `cp server/.env.example server/.env` and point `GOOGLE_APPLICATION_CREDENTIALS` at your service account key.
2. Firebase console > Authentication > Sign-in method > enable Google.
3. `cp web/.env.example web/.env.local` and fill in the web app config.
4. Install and seed:

```
npm --prefix server install
npm --prefix web install
npm --prefix server run seed
```

## Running it

```
./demo.sh run               # the server, on 3734
npm --prefix web run dev    # the dashboard, on 5734
```

`attacks.sh` sends the requests an attacker would: `post-as mei`, `post`,
`delete <id>`, `reset`, and `peek <collection>` (a direct Firestore read).

## The steps

| Tag | What it adds |
| --- | --- |
| `step-00-start` | The dashboard on the Firestore server, with `deleteEvent`. No checks at all |
| `step-01-sign-in` | Google sign-in on the dashboard. The server is unchanged |
| `step-02-verify` | The server verifies the ID token; `postedById` leaves the schema |
| `step-03-organisers` | The `organisers` collection, the `me` query, and the not-an-organiser screen |
| `step-04-ownership` | Only the organiser who posted an event can delete it |
| `step-05-rules` | Firestore rules: public event reads, everything else denied |

`./demo.sh list` shows them. See `DEMO-CONTROLS.md` for the controls, and
`tools/build-steps.sh` for how the tags are built.

The Firestore rules are deployed separately (`cd server && npx firebase-tools
deploy --only firestore:rules`), so changing step does not change them.

## Tests

```
npm --prefix web test
npm --prefix server run typecheck
```
