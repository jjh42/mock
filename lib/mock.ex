defmodule Mock do
  @moduledoc """
  Mock modules for testing purposes. Usually inside a unit test.

  Please see the README file on github for a tutorial

  ## Example

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
      end
  """

  @doc """
  Mock up `mock_module` with functions specified as a keyword
  list of function_name:implementation `mocks` for the duration
  of `test`.

  `opts` List of optional arguments passed to meck. `:passthrough` will
   passthrough arguments to the original module.

  ## Example

      with_mock(HTTPotion, [get: fn("http://example.com") ->
           "<html></html>" end] do
         # Tests that make the expected call
         assert called HTTPotion.get("http://example.com")
      end
  """
  defmacro with_mock(mock_module, opts \\ [], mocks, do: test) do
    quote do
      unquote(__MODULE__).with_mocks(
       [{unquote(mock_module), unquote(opts), unquote(mocks)}], do: unquote(test))
    end
  end

  @doc """
  Mock up multiple modules for the duration of `test`.

  ## Example
  with_mocks([{HTTPotion, opts, [{get: fn("http://example.com") -> "<html></html>" end}]}]) do
    # Tests that make the expected call
    assert called HTTPotion.get("http://example.com")
  end
  """
  defmacro with_mocks(mocks, do: test) do
    quote do
      mock_modules = mock_modules(unquote(mocks))

      try do
        unquote(test)
      after
        for m <- mock_modules, do: :meck.unload(m)
      end
    end
  end

  @doc """
  Shortcut to avoid multiple blocks when a test requires a single
  mock.

  For full description see `with_mock`.

  ## Example

      test_with_mock "test_name", HTTPotion,
        [get: fn(_url) -> "<html></html>" end] do
        HTTPotion.get("http://example.com")
        assert called HTTPotion.get("http://example.com")
      end
  """
  defmacro test_with_mock(test_name, mock_module, opts \\ [], mocks, test_block) do
    quote do
      test unquote(test_name) do
        unquote(__MODULE__).with_mock(
            unquote(mock_module), unquote(opts), unquote(mocks), unquote(test_block))
      end
    end
  end

  @doc """
  Shortcut to avoid multiple blocks when a test requires a single
  mock. Accepts a context argument enabling information to be shared
  between callbacks and the test.

  For full description see `with_mock`.

  ## Example
      setup do
        doc = "<html></html>"
        {:ok, doc: doc}
      end

      test_with_mock "test_with_mock with context", %{doc: doc}, HTTPotion, [],
        [get: fn(_url) -> doc end] do

        HTTPotion.get("http://example.com")
        assert called HTTPotion.get("http://example.com")
      end
  """
  defmacro test_with_mock(test_name, context, mock_module, opts, mocks, test_block) do
    quote do
      test unquote(test_name), unquote(context) do
        unquote(__MODULE__).with_mock(
            unquote(mock_module), unquote(opts), unquote(mocks), unquote(test_block))
      end
    end
  end

  @doc """
    Use inside a `with_mock` block to determine whether
    a mocked function was called as expected.

    ## Example

        assert called HTTPotion.get("http://example.com")
    """
  defmacro called({ {:., _, [ module , f ]} , _, args }) do
    quote do
      :meck.called unquote(module), unquote(f), unquote(args)
    end
  end

  @doc """
  Mocks up multiple modules prior to the execution of each test in a case and
  execute the callback specified.

  For full description of mocking, see `with_mocks`.

  For a full description of ExUnit setup, see
  https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html

  ## Example
      setup_with_mocks([
        {HashDict, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
      ]) do
        foo = "bar"
        {:ok, foo: foo}
      end

      test "setup_all_with_mocks base case" do
        assert HashDict.get(%{}, "http://example.com") == "<html></html>"
      end
  """
  defmacro setup_with_mocks(mocks, do: setup_block) do
    quote do
      setup do
        mock_modules(unquote(mocks))

        # The mocks are linked to the process that setup all the tests and are
        # automatically unloaded when that process shuts down

        unquote(setup_block)
      end
    end
  end

  @doc """
  Mocks up multiple modules prior to the execution of each test in a case and
  execute the callback specified with a context specified

  See `setup_with_mocks` for more details

  ## Example
      setup_with_mocks([
        {HashDict, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
      ], context) do
        {:ok, test_string: Atom.to_string(context.test)}
      end

      test "setup_all_with_mocks with context", %{test_string: test_string} do
        assert HashDict.get(%{}, "http://example.com") == "<html></html>"
        assert test_string == "test setup_all_with_mocks with context"
      end
  """
  defmacro setup_with_mocks(mocks, context, do: setup_block) do
    quote do
      setup unquote(context) do
        mock_modules(unquote(mocks))
        unquote(setup_block)
      end
    end
  end

  # Helper macro to mock modules. Intended to be called only within this module
  # but not defined as `defmacrop` due to the scope within which it's used.
  defmacro mock_modules(mocks) do
    quote do
      Enum.reduce(unquote(mocks), [], fn({m, opts, mock_fns}, ms) ->
        unless m in ms do
          # :meck.validate will throw an error if trying to validate
          # a module that was not mocked
          try do
            if :meck.validate(m), do: :meck.unload(m)
          rescue
            e in ErlangError -> :ok
          end

          :meck.new(m, opts)
        end

        unquote(__MODULE__)._install_mock(m, mock_fns)
        assert :meck.validate(m) == true

        [ m | ms] |> Enum.uniq
      end)
    end
  end

  @doc false
  def _install_mock(_, []), do: :ok
  def _install_mock(mock_module, [ {fn_name, value} | tail ]) do
    :meck.expect(mock_module, fn_name, value)
    _install_mock(mock_module, tail)
  end
end
