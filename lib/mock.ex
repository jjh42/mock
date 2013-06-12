defmodule Mock do
  @moduledoc """
  Mock modules for testing purposes. Usually inside a unit test.

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

      with_mock(HTTPPotion, [get: fn("http://example.com") ->
           "<html></html>" end] do
         # Tests that make the expected call
         assert called HTTPotion.get("http://example.com")
      end
  """
  defmacro with_mock(mock_module, opts // [], mocks, test) do
    quote do
      :meck.new(unquote(mock_module), unquote(opts))
      unquote(__MODULE__)._install_mock(unquote(mock_module), unquote(mocks))
      try do
        # Do all the tests inside so we can kill the mock
        # if any exception occurs.
        unquote(test)
        assert :meck.validate(unquote(mock_module)) == true
      after
        :meck.unload(unquote(mock_module))
      end
    end
  end

  @doc """
  Shortcut to avoid multiple blocks when a test requires a single
  mock.

  For full description see `with_mock`.

  ## Example

      test_with_mock "test_name", HTTPotion,
        [get: fn(_url) -> "<html></html>"] do
        HTTPotion.get("http://example.com")
        assert called HTTPotion.get("http://example.com")
      end
  """
  defmacro test_with_mock(test_name, mock_module, opts // [], mocks, test_block) do
    quote do
      test unquote(test_name) do
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
