defmodule ElixirCodeSmellsCatalog.Mixfile do
  use Mix.Project

  @project_description """
  Catalog of Elixir-specific code smells
  """

  @version "0.0.1"
  @source_url "https://github.com/lucasvegi/Elixir-Code-Smells"

  def project do
    [
      app: :elixir_code_smells_catalog,
      version: @version,
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      description: @project_description,
      source_url: @source_url,
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end

  defp package do
    [
      name: :elixir_code_smells_catalog,
      maintainers: ["Lucas Vegi", "Marco Tulio Valente"],
      licenses: ["MIT-License"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
