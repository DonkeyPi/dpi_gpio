defmodule Dpi.Gpio.MixProject do
  use Mix.Project

  def project do
    [
      app: :dpi_gpio,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:dpi_api, path: "../dpi_api"},
      {:circuits_gpio, "~> 1.1"}
    ]
  end
end
