[![Build Status](https://travis-ci.org/jjh42/mock.svg?branch=master)](https://travis-ci.org/jjh42/mock)
[![Coverage Status](https://coveralls.io/repos/github/jjh42/mock/badge.svg?branch=master)](https://coveralls.io/github/jjh42/mock?branch=master)

# Mock
A mocking library for the Elixir language.

We use the Erlang [meck library](https://github.com/eproxus/meck) to provide
module mocking functionality for Elixir. It uses macros in Elixir to expose the
functionality in a convenient manner for integrating in Elixir tests.

See the full [reference documentation](https://hexdocs.pm/mock/Mock.html).

## Installation
First, add mock to your `mix.exs` dependencies:

```elixir
def deps do
  [{:mock, "~> 0.3.0", only: :test}]
end
```

and run `$ mix deps.get`.

## *with_mock* - Mocking a single module
The Mock library provides the `with_mock` macro for running tests with
mocks.

For a simple example, if you wanted to test some code which calls
`HTTPotion.get` to get a webpage but without actually fetching the
webpage you could do something like this:

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "test_name" do
    with_mock HTTPotion, [get: fn(_url) -> "<html></html>" end] do
      assert "<html></html>" == HTTPotion.get("http://example.com")
    end
  end
end
````

The `with_mock` macro creates a mock module. The keyword list provides a set
of mock implementation for functions we want to provide in the mock (in
this case just `get`). Inside `with_mock` we exercise the test code
and we can check that the call was made as we expected using `called` and
providing the example of the call we expected.

## *with_mocks* - Mocking multiple modules

You can mock up multiple modules with `with_mocks`.

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "multiple mocks" do
    with_mocks([
      {Map,
       [],
       [get: fn(%{}, "http://example.com") -> "<html></html>" end]},
      {String,
       [],
       [reverse: fn(x) -> 2*x end,
        length: fn(_x) -> :ok end]}
    ]) do
      assert Map.get(%{}, "http://example.com") == "<html></html>"
      assert String.reverse(3) == 6
      assert String.length(3) == :ok
    end
  end
end
````

The second parameter of each tuple is `opts` - a list of optional arguments
passed to meck.

## Mocking input dependant output

If you have a function that should return different values depending on what the
input is, you can do as follows:

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "mock functions with multiple returns" do
    with_mock(Map, [
      get: fn
        (%{}, "http://example.com") -> "<html>Hello from example.com</html>"
        (%{}, "http://example.org") -> "<html>example.org says hi</html>"
      end
    ]) do
      assert Map.get(%{}, "http://example.com") == "<html>Hello from example.com</html>"
      assert Map.get(%{}, "http://example.org") == "<html>example.org says hi</html>"
    end
  end
end
````

## Mocking functions with different arities

You can mock functions in the same module with different arity:

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "mock functions with different arity" do
    with_mock String,
      [slice: fn(string, range)      -> string end,
       slice: fn(string, range, len) -> string end]
    do
      assert String.slice("test", 1..3) == "test"
      assert String.slice("test", 1, 3) == "test"
    end
  end
end

````

## *test_with_mock* - with_mock helper

An additional convenience macro `test_with_mock` is supplied which internally
delegates to `with_mock`. Allowing the above test to be written as follows:

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test_with_mock "test_name", HTTPotion,
    [get: fn(_url) -> "<html></html>" end] do
    HTTPotion.get("http://example.com")
    assert_called HTTPotion.get("http://example.com")
  end
end
````

The `test_with_mock` macro can also be passed a context argument
allowing the sharing of information between callbacks and the test

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  setup do
    doc = "<html></html>"
    {:ok, doc: doc}
  end

  test_with_mock "test_with_mock with context", %{doc: doc}, HTTPotion, [],
    [get: fn(_url, _headers) -> doc end] do

    HTTPotion.get("http://example.com", [foo: :bar])
    assert_called HTTPotion.get("http://example.com", :_)
  end
end
````

## *passthrough*

By default, only the functions being mocked can be accessed from within the test.
Trying to call a non-mocked function from a mocked Module will result in an error.
This can be circumvented by passing the `:passthrough` option like so:

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false
  import Mock

  test_with_mock "test_name", IO, [:passthrough], [] do
    IO.puts "hello"
    assert_called IO.puts "hello"
  end
end
````

## *setup_with_mocks* - Configure all tests to have the same mocks

The `setup_with_mocks` mocks up multiple modules prior to every single test
along while calling the provided setup block. It is simply an integration of the
`with_mocks` macro available in this module along with the [`setup`](https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#setup/1)
macro defined in elixir's `ExUnit`.

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false
  import Mock

  setup_with_mocks([
    {Map, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
  ]) do
    foo = "bar"
    {:ok, foo: foo}
  end

  test "setup_with_mocks" do
    assert Map.get(%{}, "http://example.com") == "<html></html>"
  end
end
````

The behaviour of a mocked module within the setup call can be overridden using any
of the methods above in the scope of a specific test. Providing this functionality
by `setup_all` is more difficult, and as such, `setup_all_with_mocks` is not currently
supported.

Currently, mocking modules cannot be done asynchronously, so make sure that you
are not using `async: true` in any module where you are testing.

Also, because of the way mock overrides the module, it must be defined in a
separate file from the test file.

## NOT SUPPORTED - Mocking internal function calls

A common issue a lot of developers run into is Mock's lack of support for mocking
internal functions. Mock will behave as follows:

```` elixir
defmodule MyApp.IndirectMod do

  def value do
    1
  end

  def indirect_value do
    value()
  end

  def indirect_value_2 do
    MyApp.IndirectMod.value()
  end

end
````

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false
  import Mock

  test "indirect mock" do
    with_mocks([
      { MyApp.IndirectMod, [:passthrough], [value: fn -> 2 end] },
    ]) do
      # The following assert succeeds
      assert MyApp.IndirectMod.indirect_value_2() == 2
      # The following assert also succeeds
      assert MyApp.IndirectMod.indirect_value() == 1
    end
  end
end
````

It is important to understand that only fully qualified function calls get mocked.
The reason for this is because of the way Meck is structured. Meck creates a thin wrapper module with the name of the mocked module (and passes through any calls to the original
Module in case passthrough is used). The original module is renamed, but otherwise unmodified. Once the call enters the original module, the local function call jumps stay in the module.

Big thanks to @eproxus (author of Meck) who helped explain this to me. We're looking
into some alternatives to help solve this, but it is something to be aware of in the meantime. The issue is being tracked in [Issue 71](https://github.com/jjh42/mock/issues/71).

In order to workaround this issue, the `indirect_value` can be rewritten like so:
```` elixir
  def indirect_value do
    __MODULE__.value()
  end
````

Or, like so:

```` elixir
  def indirect_value do
    MyApp.IndirectMod.value()
  end
````

## Assert called

You can check whether or not your mocked module was called.

### Assert called - specific value

It is possible to assert that the mocked module was called with a specific input.

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "test_name" do
    with_mock HTTPotion, [get: fn(_url) -> "<html></html>" end] do
      HTTPotion.get("http://example.com")
      assert_called HTTPotion.get("http://example.com")
    end
  end
end
````

### Assert called - wildcard

It is also possible to assert that the mocked module was called with any value
by passing the `:_` wildcard.

```` elixir
defmodule MyTest do
  use ExUnit.Case, async: false

  import Mock

  test "test_name" do
    with_mock HTTPotion, [get: fn(_url) -> "<html></html>" end] do
      HTTPotion.get("http://example.com")
      assert_called HTTPotion.get(:_)
    end
  end
end
````

## Tips
The use of mocking can be somewhat controversial. I personally think that it
works well for certain types of tests. Certainly, you should not overuse it. It
is best to write as much as possible of your code as pure functions which don't
require mocking to test. However, when interacting with the real world (or web
services, users etc.) sometimes side-effects are necessary. In these cases,
mocking is one useful approach for testing this functionality.

Also, note that Mock has a global effect so if you are using Mocks in multiple
tests set `async: false` so that only one test runs at a time.

## Help
Open an issue.

## Suggestions
I'd welcome suggestions for improvements or bugfixes. Just open an issue.
