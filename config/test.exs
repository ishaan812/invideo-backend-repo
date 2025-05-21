import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shader_server, ShaderServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fY6511K77A3k7DmXPXR+EtXCMC5kXLb4vCky4b+wagN4ic6VgpKv7SpAtQeTAK/6",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
