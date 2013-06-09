defmodule Mock.Mixfile do
  use Mix.Project

  def project do
    [ app: :mock,
      name: "Mock",
      source_url: "https://github.com/jjh42/mock",
      homepage_url: "http://jjh42.github.io/mock",
      version: "0.0.1",
      env: [
          dev: [deps: deps ++ dev_deps],
          test: [deps: deps] ,
          prod: [deps: deps]]]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ {:meck,"0.7.2", [github: "eproxus/meck"]}]
  end

  # Dependencies only needed during development.
  defp dev_deps do
    [{ :ex_doc, github: "elixir-lang/ex_doc" }]
  end
end


defmodule Mix.Tasks.Docs.Ghpages do
  use Mix.Task

  @moduledoc """
  A task for uploading documentation to gh-pages.
  """

  defp run!(command) do
    if Mix.shell.cmd(command) != 0 do
      raise Mix.Error, message: "command `#{command}` failed"
    end
    :ok
  end

  def run(_) do
    File.rm_rf "docs"
    Mix.Task.run "docs"
    # First figure out the git remote to use based on the
    # git remote here.
    git_remote = Keyword.get(
        Regex.captures(%r/\: (?<git>.*)/g,
            :os.cmd 'git remote show -n origin | grep "Push  URL"'), :git)
    Mix.shell.info "Git remote #{git_remote}"
    File.cd! "docs"
    run! "git init ."
    run! "git add ."
    run! "git commit -a -m \"Generated docs\""
    run! "git remote add origin #{git_remote}"
    run! "git push origin master:gh-pages --force"
  end
end
