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
        {Map, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
      ]) do
        foo = "bar"
        {:ok, foo: foo}
      end

      test "setup_all_with_mocks base case" do
        assert Map.get(%{}, "http://example.com") == "<html></html>"
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
        {Map, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
      ], context) do
        {:ok, test_string: Atom.to_string(context.test)}
      end

      test "setup_all_with_mocks with context", %{test_string: test_string} do
        assert Map.get(%{}, "http://example.com") == "<html></html>"
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

          path_to_file = :code.which m
          # IO.inspect {m, opts}
          # IO.inspect {:beam_disasm.file(File.read!(path_to_file))}
          # IO.inspect {:erts_debug.df m}
          IO.inspect(:file.write_file("/tmp/disasm.asm", :io_lib.fwrite("~p.\n", [:beam_disasm.file(:code.which m)])))
          IO.inspect(:compile.noenv_file("/tmp/disasm.asm", [:from_asm]))
          # IO.inspect(:code.which MyApp.IndirectMod)
          :meck.new(m, opts)
        end

        unquote(__MODULE__)._install_mock(m, mock_fns)
        assert :meck.validate(m) == true

        # IO.inspect({m, opts, mock_fns})
        # IO.inspect {:beam_disasm.file(File.read!(path_to_file))}

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

# https://www.youtube.com/watch?v=5T5pYVw5WtY

# {:function, :indirect_value, 0, 10,
# [
# {:line, 1},
# {:label, 9},
# {:func_info, {:atom, MyApp.IndirectMod}, {:atom, :indirect_value}, 0},
# {:label, 10},
# {:call_only, 0, {MyApp.IndirectMod, :value, 0}}
# ]},
# {:function, :indirect_value_2, 0, 12,
# [
# {:line, 2},
# {:label, 11},
# {:func_info, {:atom, MyApp.IndirectMod}, {:atom, :indirect_value_2}, 0},
# {:label, 12},
# {:line, 3},
# {:call_ext_only, 0, {:extfunc, MyApp.IndirectMod, :value, 0}}
# ]},
# ```
#
# Note that specifying the module and omitting it compiles to different instructions on the beam.
#
# I know I’m probably entering the realm of things I shouldn’t touch, but let’s overlook that for a moment.
#
# What I want to achieve is to take the disassembled beam, replace `{:call_only, 0, {MyApp.IndirectMod, :value, 0}}` with `{:call_ext_only, 0, {:extfunc, MyApp.IndirectMod, :value, 0}}`, reassemble it, and write it back out to a file.
#
# The only missing peace is some sort of `:beam_asem` command which I couldn’t find through my research.







# path_to_file = :code.which Elixir.MyApp.IndirectMod
# {:beam_disasm.file(File.read!(path_to_file))}
# {:ok,{_,[{:abstract_code,{_,ac}}]}}  = :beam_lib.chunks(path_to_file,[:abstract_code])


# [
#   {:attribute, 1, :file, {'lib/temp.ex', 1}},
#   {:attribute, 1, :module, MyApp.IndirectMod},
#   {:attribute, 1, :compile, :no_auto_import},
#   {:attribute, 1, :export,
#    [__info__: 1, indirect_value: 0, indirect_value_2: 0, value: 0]},
#   {:attribute, 1, :spec,
#    {{:__info__, 1},
#     [
#       {:type, 1, :fun,
#        [
#          {:type, 1, :product,
#           [
#             {:type, 1, :union,
#              [
#                {:atom, 1, :attributes},
#                {:atom, 1, :compile},
#                {:atom, 1, :functions},
#                {:atom, 1, :macros},
#                {:atom, 1, :md5},
#                {:atom, 1, :module},
#                {:atom, 1, :deprecated}
#              ]}
#           ]},
#          {:type, 1, :any, []}
#        ]}
#     ]}},
#   {:function, 0, :__info__, 1,
#    [
#      {:clause, 0, [{:atom, 0, :module}], [], [{:atom, 0, MyApp.IndirectMod}]},
#      {:clause, 0, [{:atom, 0, :functions}], [],
#       [
#         {:cons, 0, {:tuple, 0, [{:atom, 0, :indirect_value}, {:integer, 0, 0}]},
#          {:cons, 0,
#           {:tuple, 0, [{:atom, 0, :indirect_value_2}, {:integer, 0, 0}]},
#           {:cons, 0, {:tuple, 0, [{:atom, 0, :value}, {:integer, 0, 0}]},
#            {nil, 0}}}}
#       ]},
#      {:clause, 0, [{:atom, 0, :macros}], [], [nil: 0]},
#      {:clause, 0, [{:atom, 0, :attributes}], [],
#       [
#         {:call, 0,
#          {:remote, 0, {:atom, 0, :erlang}, {:atom, 0, :get_module_info}},
#          [{:atom, 0, MyApp.IndirectMod}, {:atom, 0, :attributes}]}
#       ]},
#      {:clause, 0, [{:atom, 0, :compile}], [],
#       [
#         {:call, 0,
#          {:remote, 0, {:atom, 0, :erlang}, {:atom, 0, :get_module_info}},
#          [{:atom, 0, MyApp.IndirectMod}, {:atom, 0, :compile}]}
#       ]},
#      {:clause, 0, [{:atom, 0, :md5}], [],
#       [
#         {:call, 0,
#          {:remote, 0, {:atom, 0, :erlang}, {:atom, 0, :get_module_info}},
#          [{:atom, 0, MyApp.IndirectMod}, {:atom, 0, :md5}]}
#       ]},
#      {:clause, 0, [{:atom, 0, :deprecated}], [], [nil: 0]}
#    ]},
#   {:function, 7, :indirect_value, 0,
#    [{:clause, 7, [], [], [{:call, 8, {:atom, 8, :value}, []}]}]},
#   {:function, 11, :indirect_value_2, 0,
#    [{:clause, 11, [], [], [{:call, 8, {:atom, 8, :value}, []}]}]},
#   {:function, 3, :value, 0, [{:clause, 3, [], [], [{:integer, 0, 1}]}]}
# ]
