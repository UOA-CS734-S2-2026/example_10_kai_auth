// COMPSCI 734 - the resolvers: one function per field the schema promises.
//
// Every resolver receives the request context as its third argument, holding
// the caller the token proved (or null). Reads ignore it; writes require it.

import { announce } from '../notify';
import { store } from '../store';
import { requireSignedIn, type Context } from '../auth';
import type { KaiEvent, NewEvent, User } from '../data';

// What the client may send: everything except who it is.
type PostArgs = Omit<NewEvent, 'postedById'>;

type Resolvers = {
  Query: {
    events: (parent: unknown, args: { activeOnly?: boolean }) => Promise<KaiEvent[]>;
    event: (parent: unknown, args: { id: string }) => Promise<KaiEvent | undefined>;
  };
  Event: {
    postedBy: (event: KaiEvent) => Promise<User | undefined>;
  };
  Mutation: {
    eatPortion: (parent: unknown, args: { id: string }) => Promise<KaiEvent | undefined>;
    postEvent: (parent: unknown, args: PostArgs, context: Context) => Promise<KaiEvent>;
    deleteEvent: (
      parent: unknown,
      args: { id: string },
      context: Context,
    ) => Promise<string | undefined>;
  };
};

export const resolvers: Resolvers = {
  Query: {
    events: (_, { activeOnly }) => store.events(activeOnly),
    event: (_, { id }) => store.event(id),
  },

  // A resolver on Event itself, not on Query. Ask for postedBy and this runs,
  // once per event; leave it out of the query and it never runs at all. The
  // N+1 problem did not vanish, it moved to the server, where at real scale a
  // pattern called a dataloader batches the lookups away.
  Event: {
    postedBy: (event) => store.user(event.postedById),
  },

  Mutation: {
    eatPortion: (_, { id }) => store.eatPortion(id),

    // Write first, tell people second, and in that order for a reason. The
    // write is the thing that is true; the notification is an invitation to
    // come and look at it. If the send fails the kai is still posted, and
    // announce() is written to make sure a failure cannot take the post down
    // with it.
    postEvent: async (_, args, context) => {
      const caller = requireSignedIn(context);
      console.log(`post: requested by ${caller.email ?? caller.uid} (verified token)`);
      const event = await store.postEvent({ ...args, postedById: caller.uid });
      await announce(event.name, event.location, event.portionsLeft);
      return event;
    },

    deleteEvent: (_, { id }, context) => {
      requireSignedIn(context);
      return store.deleteEvent(id);
    },
  },
};
