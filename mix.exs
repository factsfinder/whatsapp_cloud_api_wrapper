defmodule WhatsappCloudApiWrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :whatsapp_cloud_api_wrapper,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
     An unofficial Elixir client for Whatsapp Cloud API.
    """
  end

  defp docs do
    []
  end


  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:req, "~> 0.4.0"}
    ]
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Phanindra Veera"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/factsfinder/whatsapp_cloud_api_wrapper",
              "Docs" => "https://hexdocs.pm/whatsapp_cloud_api_wrapper/"}
     ]
  end

end
