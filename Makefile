# Backend Makefile

.PHONY: setup deps compile clean test server iex

# Default target
all: setup compile

# Initial setup
setup:
	mix local.hex --force
	mix local.rebar --force
	mix deps.get

# Get dependencies
deps:
	mix deps.get
	mix deps.compile

# Compile the project
compile:
	mix compile

# Clean build artifacts
clean:
	mix clean
	rm -rf _build
	rm -rf deps

# Run tests
test:
	mix test

# Start the Phoenix server
server:
	mix phx.server

# Start IEx with the application
iex:
	iex -S mix

# Format code
format:
	mix format

# Run database migrations
migrate:
	mix ecto.migrate

# Reset database
db-reset:
	mix ecto.reset

# Clean and reinstall everything
reset: clean setup compile 