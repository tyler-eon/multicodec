defmodule Multicodec.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/tyler-eon/multicodec"

  def project do
    [
      app: :multicodec,
      version: @version,
      elixir: "~> 1.18",
      description: "An Elixir implementation of the multicodec specification for self-describing codec identifiers.",
      package: package(),
      deps: deps(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def package do
    [
      name: "multicodec_ex",
      maintainers: ["Tyler Eon"],
      licenses: ["MPL-2.0"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "Multicodec",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp deps do
    [
      {:varint, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
