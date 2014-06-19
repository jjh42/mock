defmodule Mock.Mixfile do
  use Mix.Project

  def project do
    [ app: :mock,
      name: "Mock",
      source_url: "https://github.com/jjh42/mock",
      homepage_url: "http://jjh42.github.io/mock",
      version: "0.0.4",
      deps: deps ]
  end

  defp deps do
    deps(Mix.env)
  end

  defp deps(:dev) do
    prod_deps ++ dev_deps
  end

  defp deps(_) do
    prod_deps
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp prod_deps do
    [ {:meck,"0.8.2", [github: "eproxus/meck", tag: "0.8.2"]}]
  end

  # Dependencies only needed during development.
  defp dev_deps do
    [{ :docs_ghpages, github: "jjh42/docs_ghpages" }]
  end
end
