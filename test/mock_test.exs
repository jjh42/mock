Code.require_file "test_helper.exs", __DIR__


defmodule MockTest do
  use ExUnit.Case, async: false
  import Mock

  setup_all do
    foo = "bar"
    {:ok, foo: foo}
  end

  test "simple mock" do
    with_mock String,
        [reverse: fn(x) -> 2*x end] do
      assert String.reverse(3) == 6
    end
  end

  test "called" do
    with_mock String,
       [reverse: fn(x) -> 2*x end,
        length: fn(x) -> :ok end] do
      String.reverse 3
      assert :meck.called String, :reverse, [3]
      assert called String.reverse(3)
      refute called String.reverse(2)
      refute called String.length(3)
    end
  end

  test_with_mock "test_with_mock",
    String,
    [reverse: fn(_x) -> :ok end] do
    assert String.reverse 3
    assert called String.reverse(3)
    refute called String.reverse(4)
  end

  test_with_mock "test_with_mock with context", %{foo: foo}, String, [],
    [reverse: fn(_x) -> :ok end] do
    assert String.reverse 3
    assert foo == "bar"
    assert called String.reverse(3)
    refute called String.reverse(4)
  end

  test_with_mock "passthrough", HashDict, [:passthrough],
    [] do
    hd = HashDict.put(HashDict.new(), :a, 1)
    assert HashDict.get(hd, :a) == 1
    assert called HashDict.new()
    assert called HashDict.get(hd, :a)
    refute called HashDict.get(hd, :b)
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
