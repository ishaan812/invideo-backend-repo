defmodule ShaderServerWeb.Router do
  use ShaderServerWeb, :router
  import Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ShaderServerWeb do
    pipe_through :api

    post "/generate-shader", GenerateShaderJson, :generate_shader
  end
end
