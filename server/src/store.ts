// COMPSCI 734 - which store the server actually uses.
//
// This file exists so that exactly one line has to change when the data moves
// out of the process and into a database. Everything else - both REST routes
// and every GraphQL resolver - imports from here and never learns the
// difference.

export { store, STORE_NAME } from './store-firestore';
