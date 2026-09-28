import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import cors from 'cors';
import express from 'express';

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

const server = new ApolloServer({ typeDefs, resolvers });
await server.start();

app.use('/graphql', cors(), express.json(), expressMiddleware(server));

app.listen(PORT, () => {
  console.log(`Kai Events server listening on http://localhost:${PORT} (store: ${STORE_NAME})`);
  console.log(`GraphQL and Apollo Sandbox at http://localhost:${PORT}/graphql`);
  console.log(`Portions decay every ${DECAY_INTERVAL_MS / 1000} seconds.`);
  store.startDecay();
});
