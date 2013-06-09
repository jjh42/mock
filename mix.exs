defmodule Mock.Mixfile do
  use Mix.Project

  def project do
    [ app: :mock,
      version: "0.0.1",
      deps: deps ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ {:meck,"0.7.2", [github: "eproxus/meck"]} ]
  end
end
