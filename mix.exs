defmodule Mock.Mixfile do
  use Mix.Project

  def project do
    [ app: :mock,
      name: "Mock",
      version: "0.1.0",
      elixir: "~> 1.0",
      description: description,
      package: package,
      deps: deps ]
  end

  defp deps do
    [
      {:meck, "~> 0.8.2"},
      {:docs_ghpages, github: "jjh42/docs_ghpages", only: :dev}
    ]
  end

  defp description do
    """
    A mocking libary for the Elixir language.

    We use the Erlang meck library to provide module mocking
    functionality for Elixir. It uses macros in Elixir to expose
    the functionality in a convenient manner for integrating in
    Elixir tests.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      contributors: [
        "Dave Thomas",
        "Jonathan J Hunt",
        "Joseph Wilk",
        "Josh Adams",
        "Jérémy",
        "matt.freer",
        "Mikhail S. Pobolovets",
        "parroty",
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/jjh42/mock",
        "Docs"   => "https://jjh42.github.io/mock"
      }
    ]
  end
end
