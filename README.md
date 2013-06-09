[![Build Status](https://travis-ci.org/jjh42/meckex.png?branch=master)](https://travis-ci.org/jjh42/meckex)

# Meckex
A mocking libary for the Elixir language.

We use the Erlang  [meck library](https://github.com/eproxus/meck) to provide module
mocking functionality for Elixir. It uses macros in Elixir to expose
the functionality in a convenient manner for integrating in Elixir tests.

For example,

	