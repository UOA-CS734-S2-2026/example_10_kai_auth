import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import cors from 'cors';
import express from 'express';

import { callerFrom, type Context } from './auth';
import { DECAY_INTERVAL_MS } from './data';
import { resolvers } from './graphql/resolvers';
import { typeDefs } from './graphql/schema';
import { rest } from './rest';
import { store, STORE_NAME } from './store';

const PORT = 3734;

const app = express();
app.use(cors());
app.use(express.json());
app.use(rest);

const server = new ApolloServer<Context>({
  typeDefs,
  resolvers,
  // Stack traces in error responses tell an attacker where your files are and
  // which libraries you run. Off, and it also keeps curl output readable.
  includeStacktraceInErrorResponses: false,
});
await server.start();

// The context function runs once per request, before any resolver. It is the
// one place the token is read, so no resolver can forget to check it: they
// all receive the verified caller (or null) as their third argument.
app.use(
  '/graphql',
  cors(),
  express.json(),
  expressMiddleware(server, {
    context: async ({ req }) => ({ caller: await callerFrom(req.headers.authorization) }),
  }),
);

app.listen(PORT, () => {
  console.log(`Kai Events server listening on http://localhost:${PORT} (store: ${STORE_NAME})`);
  console.log(`GraphQL and Apollo Sandbox at http://localhost:${PORT}/graphql`);
  console.log(`Portions decay every ${DECAY_INTERVAL_MS / 1000} seconds.`);
  store.startDecay();
});
