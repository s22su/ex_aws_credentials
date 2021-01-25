defmodule AwsCredentials.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_credentials,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:hackney, "~> 1.17"},
      {:exvcr, "~> 0.11", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
