Code.require_file "test_helper.exs", __DIR__

defmodule MockTest do
  use ExUnit.Case
  import Mock

  test "simple mock" do
    with_mock Dummy,
        [foo: fn(x) -> 2*x end] do
      assert Dummy.foo(3) == 6
    end
  end

  test "called" do
    with_mock Dummy,
       [foo: fn(x) -> 2*x end,
        bar: fn() -> :ok end] do
      Dummy.foo 3
      assert :meck.called Dummy, :foo, [3]
      assert called Dummy.foo(3)
      refute called Dummy.foo(2)
      refute called Dummy.bar(3)
    end
  end

  test_with_mock "test with mock",
    Dummy,
    [get: fn(_x) -> :ok end] do
    assert Dummy.get 3
    assert called Dummy.get(3)
    refute called Dummy.get(4)
  end

  test "restore after exception" do
    assert String.downcase("A") == "a"
    try do
      with_mock String,
          [downcase: fn(x) -> x end] do
        assert String.downcase("A") == "A"
        raise "some error"
      end
    rescue
      RuntimeError -> :ok
    end
    assert String.downcase("A") == "a"
  end

end
