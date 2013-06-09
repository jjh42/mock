[![Build Status](https://travis-ci.org/jjh42/meckex.png?branch=master)](https://travis-ci.org/jjh42/meckex)

# Mock
A mocking libary for the Elixir language.

We use the Erlang  [meck library](https://github.com/eproxus/meck) to provide module
mocking functionality for Elixir. It uses macros in Elixir to expose
the functionality in a convenient manner for integrating in Elixir tests.

See the full [reference documentation](http://jjh42.github.io/mock).

## Example

For a simple example, if you wanted to test some code which calls
`HTTPotion.get` to get a webpage but without actually fetching the
webpage you could do something like this.

```` elixir
defmodule MyTest do
  use ExUnit.Case
  import Mock

  test "get" do
    with_mock HTTPotion,
        [get: fn("http://example.com", _headers) ->
                HTTPotion.Response.new(status_code: 200,
                    body: "hello") end] do
      # Code which calls HTTPotion.get
	  # Check that the call was made as we expected
      assert called HTTPotion.get("http://example.com", :_)
    end
  end
````

The `with_mock` creates a mock module. The keyword list provides a set
of mock implementation for functions we want to provide in the mock (in
this case just `get`). Inside `with_mock` we exercise the test code
and we can check that the call was made as we expected using `called` and
providing the example of the call we expected (the second argument `:_` has a 
special meaning of matching anything).

Currently, mocking modules cannot be done asynchronously, so make sure that you
are not using `async: true` in any module where you are testing.

## Tips

The use of mocking can be somewhat controversial. I personally think that it works
well for certain types of tests. Certainly, you should not overuse it. It is
best to write as much as possible of your code as pure functions which don't
require mocking to test. However, when interacting with the real world (or web services,
users etc.) sometimes side-effects are necessary. In these cases, mocking is one
useful approach for testing this functionality.

## Help

Open an issue.


## Suggestions

I'd welcome suggestions for improvements or bugfixes. Just open an issue.
