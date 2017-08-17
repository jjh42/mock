defmodule Mock.Mixfile do
  use Mix.Project

  @version "0.2.1"

  def project do
    [ app: :mock,
      name: "Mock",
      version: @version,
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      docs: [source_ref: "v#{@version}", main: "Mock"],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test],
      deps: deps() ]
  end

  defp deps do
    [
      {:meck, "~> 0.8.7"},
      {:docs_ghpages, github: "jjh42/docs_ghpages", only: :dev},
      {:markdown, github: "devinus/markdown", only: :dev},
      {:excoveralls, "~> 0.4", only: :test}
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
        "Daniel Olshansky",
        "Dave Thomas",
        "Jonathan J Hunt",
        "Joseph Wilk",
        "Josh Adams",
        "Jérémy",
        "matt.freer",
        "Mikhail S. Pobolovets",
        "parroty",
        "xieyunzi",
      ],
      maintainers: [
        "Daniel Olshansky (olshansky.daniel@gmail.com)",
        "Jonathan J Hunt (j@me.net.nz)"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/jjh42/mock",
        "Docs"   => "https://jjh42.github.io/mock"
      }
    ]
  end
end
