Code.require_file "test_helper.exs", __DIR__

defmodule MockSetupTest do
  use ExUnit.Case, async: false
  import Mock

  setup_with_mocks([
    {HashDict, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
  ]) do
    foo = "bar"
    {:ok, foo: foo}
  end

  test "setup_with_mocks" do
    assert HashDict.get(%{}, "http://example.com") == "<html></html>"
  end

  test "setup_with_mocks with test context", %{foo: foo} do
    assert HashDict.get(%{}, "http://example.com") == "<html></html>"
  end

  test_with_mock "setup_with_mocks respects test specific override", HashDict, [],
    [get: fn(%{}, "http://example.com") -> "<html>override</html>" end] do

    assert HashDict.get(%{}, "http://example.com") == "<html>override</html>"
  end

  test_with_mock "setup_with_mocks with test context respects test specific override", %{foo: foo},
    HashDict, [], [get: fn(%{}, "http://example.com") -> "<html>override</html>" end] do

    assert HashDict.get(%{}, "http://example.com") == "<html>override</html>"
  end

end

defmodule MockSetupTestWithContext do
  use ExUnit.Case, async: false
  import Mock

  setup_with_mocks([
    {HashDict, [], [get: fn(%{}, "http://example.com") -> "<html></html>" end]}
  ], context) do
    {:ok, test_string: Atom.to_string(context.test)}
  end

  test "setup_with_mocks with setup context" do
    assert HashDict.get(%{}, "http://example.com") == "<html></html>"
  end

  test "setup_with_mocks with setup context and test context", %{test_string: test_string} do
    assert HashDict.get(%{}, "http://example.com") == "<html></html>"
    assert test_string == "test setup_with_mocks with setup context and test context"
  end

end
