# Define the shell to use
SHELL := /bin/bash

# Define the name of the Docker image
IMAGE_NAME := dbt-bigquery-monitoring-base

test:
	uv run pytest

lint:
	uv run sqlfluff lint

fix:
	uv run sqlfluff fix

build:
	docker build -t $(IMAGE_NAME):main .
