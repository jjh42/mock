defmodule A do
  defmacro __using__(_opts) do
    quote do
      def avoid_during_test(foo) do
        {:error, "don't ever want to get here during test"}
      end
    end
  end
end

defmodule B do
  use A
  def init() do
    avoid_during_test(:ignored_in_test_anyway)
  end
end
