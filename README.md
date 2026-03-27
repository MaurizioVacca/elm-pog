# README

This is an experiment to connect Elm to a SQL database, without nothing in between. As it is right now, I see two main options:

1. running Elm through Node.js;
2. use `elm-pages` as dependency.

I will most likely start from the second option and eventually work my way towards the first. Not having `elm-pages` as dependency can allow more people to use the library although a server will be obviously required because here’s where SQL database lies.

## Inspirations

The main inspiration comes from libraries such as https://github.com/lpil/pog and https://github.com/dillonkearns/elm-graphql.

## What to expect from this module

A small, curated, PostgreSQL client for Elm with:

- a (hopefully) hassle-free way to handle DB connection;
- a way to decode returned values;
- a way to perform “query as text” with the possibility to pass down dynamic parameters;
- a CLI to configure and scaffold `elm-pog` in existing `elm-pages` projects.

## Future plans

Since the project works on `elm-pages script`, a new set of opportunities will open up:

- run migrations through `squalo`;
- generate Elm code from `sql` files.
- ensure test coverage.


## Milestones and goals

### Done

- [x] Set up a fresh project with `elm-pages`
- [x] Create a repository
- [x] Create a PoC with a working DB connection
- [x] Create `elm-pog` client
- [x] Allow parametric queries

### In Progress

- [ ] Ensure .env file exists
- [ ] Add `update config` command
- [ ] Start working towards scaffolding
- [ ] Publish to NPM