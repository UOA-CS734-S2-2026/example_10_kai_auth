// COMPSCI 734 - the resolvers: one function per field the schema promises.

import { announce } from '../notify';
import { store } from '../store';
import type { KaiEvent, NewEvent, User } from '../data';

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
    postEvent: (parent: unknown, args: NewEvent) => Promise<KaiEvent>;
    deleteEvent: (parent: unknown, args: { id: string }) => Promise<string | undefined>;
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
    postEvent: async (_, args) => {
      const event = await store.postEvent(args);
      await announce(event.name, event.location, event.portionsLeft);
      return event;
    },

    deleteEvent: (_, { id }) => store.deleteEvent(id),
  },
};
