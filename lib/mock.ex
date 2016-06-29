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
      mock_modules =
      unquote(mocks)
      |> Enum.reduce([], fn({m, opts, mock_fns}, ms) ->
        unless m in ms do
          :meck.new(m, opts)
        end

        unquote(__MODULE__)._install_mock(m, mock_fns)
        assert :meck.validate(m) == true

        [ m | ms] |> Enum.uniq
      end)

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

  @doc false
  def _install_mock(_, []), do: :ok
  def _install_mock(mock_module, [ {fn_name, value} | tail ]) do
    :meck.expect(mock_module, fn_name, value)
    _install_mock(mock_module, tail)
  end
end
