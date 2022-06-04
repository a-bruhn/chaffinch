# Chaffinch

[![Build](https://circleci.com/gh/a-bruhn/chaffinch.svg?style=svg&circle-token)](https://app.circleci.com/pipelines/github/a-bruhn/chaffinch?branch=master&filter=all)
![codecov](https://codecov.io/gh/a-bruhn/chaffinch/branch/master/graph/badge.svg)

Chaffinch is a text editor written in Elixir using the [Ratatouille](https://github.com/ndreynolds/ratatouille) toolkit.
At the moment, the project is basically a learning exercise for me to get comfortable with Elixir.
I do not in any way claim that this code is idiomatic or well thought out, but I hope it might become so.

## How to run it

[Install elixir](https://elixir-lang.org/install.html), clone this repository, and build a release:

```bash
mix deps.get
mix compile
mix release
```

At the moment, you have to set the file to be opened though an environment variable. You can start the application with a file opened like this:

```bash
export CHAFFINCH_FILE=./welcome.txt && _build/dev/rel/chaffinch/bin/chaffinch start
```

## Roadmap

- [x] Basic text editing in frame
- [x] Status and message bars
  - [x] Basic control shortcuts
  - [x] File name and status at the top
- [ ] Handle text dimensions exceeding the window size
  - [x] X/Y scrolling
  - [ ] Scrollbars
- [x] File I/O
  - [x] Loading a file ~with command line arguments~ through an environment variable
  - [x] Saving the current state
  - [x] Prompt when trying to close in a dirty state
- [ ] More advanced controls, user configurations
- [ ] Improved design
- [ ] Menus/tabs ?
- [ ] Syntax highlighting
