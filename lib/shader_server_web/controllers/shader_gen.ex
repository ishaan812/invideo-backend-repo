defmodule ShaderServerWeb.GenerateShaderJson do
  use ShaderServerWeb, :controller

  @gemini_api_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent"
  @webgl_shader_prompt """
  <prompt>
  <role>You are a WebGL shader generator.</role>
  <task>Generate a complete, valid WebGL shader program as a single GLSL code block containing both the vertex and fragment shaders.</task>
  <output>
    <format>Respond with a JSON object containing a single key: "shader".</format>
    <structure>
      The value of "shader" must be a multiline string containing both shaders in the following format:
        1. Vertex shader code first
        2. Then a single line: // FRAGMENT_SHADER_START
        3. Followed by the fragment shader code
      
      Example format:
      {
        "shader": "<vertex shader code>
      // FRAGMENT_SHADER_START
      <fragment shader code>"
      }
    </structure>
    <rules>
      <rule>Do not escape newlines or indentation; preserve raw GLSL formatting.</rule>
      <rule>Dont use comments in the shader code</rule>
      <rule>The vertex shader must include a `main` function that sets `gl_Position`.</rule>
      <rule>The vertex shader will receive `attribute vec2 a_position;` (normalized device coordinates for a full-screen quad). Ensure `gl_Position` is set using `a_position` (e.g., `gl_Position = vec4(a_position, 0.0, 1.0);`).</rule>
      <rule>The fragment shader must:
        - Begin with a precision qualifier (e.g., `precision mediump float;`)
        - Include a `main` function that sets `gl_FragColor`
      </rule>
      <rule>The fragment shader can optionally utilize `uniform vec2 u_resolution;` (canvas dimensions in pixels) and `uniform float u_time;` (time in seconds for animation).</rule>
      <rule>Output only the JSON object, with no additional text or explanation.</rule>
      <rule>The shader code must be valid and executable in a standard WebGL pipeline, suitable for a full-screen quad.</rule>
    </rules>
  </output>
  </prompt>
  """

  def generate_shader(conn, %{"prompt" => prompt} = _params) do
    api_key = Application.get_env(:shader_server, :gemini_api_key)

    case api_key do
      nil ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "GEMINI_API_KEY not configured"})

      key ->
        url = "#{@gemini_api_url}?key=#{key}"

        request_body = %{
          system_instruction: %{
            parts: [
              %{
                text: @webgl_shader_prompt
              }
            ]
          },
          contents: [
            %{
              parts: [
                %{text: prompt}
              ]
            }
          ],
          generationConfig: %{
            responseMimeType: "application/json",
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
          },
        }

        case HTTPoison.post(url, Jason.encode!(request_body), [{"Content-Type", "application/json"}], [recv_timeout: 60000]) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, response} ->
                shader_text = get_in(response, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
                shader_json = Jason.decode!(shader_text)
                shader_code = get_in(shader_json, ["shader"])
                conn
                |> put_status(:ok)
                |> json(%{shader: shader_code})

              {:error, _} ->
                conn
                |> put_status(:internal_server_error)
                |> json(%{error: "Failed to parse API response"})
            end

          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            conn
            |> put_status(status_code)
            |> json(%{error: "API request failed", details: body})

          {:error, %HTTPoison.Error{reason: reason}} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Request failed", details: reason})
        end
    end
  end

  def generate_shader(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required 'prompt' parameter"})
  end
end
