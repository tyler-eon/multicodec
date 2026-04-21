defmodule Multicodec.MixProject do
  use Mix.Project

  def project do
    [
      app: :multicodec,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "An Elixir implementation of the multicodec specification for self-describing codec identifiers.",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      name: "multicodec",
      maintainers: ["Tyler Eon"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/tyler-eon/multicodec"
      }
    ]
  end

  defp deps do
    [
      {:varint, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
