defmodule Mock do
  @moduledoc """
    Mock modules for testing.
    """

  @doc """
       Mock up a module for the duration of a test.

       with_mock(HTTPPotion, [get: fn("http://example.com") ->
                "<html></html>" end] do
              # Tests that make the expected call
              assert called HTTPotion.get("http://example.com")
            end
       """
  defmacro with_mock(mock_module, mocks, test) do
    quote do
      :meck.new(unquote(mock_module))
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
    Use inside a with_mock block to determine whether
    a function was called.

    assert called(HTTPotion.get("http://example.com")
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
