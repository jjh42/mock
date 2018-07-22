defmodule BTest do
  use ExUnit.Case
  import Mock
  test "my test" do
    with_mocks([
      {B, [:passthrough], [avoid_during_test: fn(_arg) -> :ok end]}
    ]) do
       B.init()
       assert(true)
    end
  end
end
