defmodule Foo do
  def bar, do: :qux
end

defmodule MockTest.Helper do
  import Mock

  def foo do
    with_mock Foo, [bar: fn -> :bar end] do
      Foo.bar
    end
  end
end
