# Define the shell to use
SHELL := /bin/bash

# Define the name of the Docker image
IMAGE_NAME := dbt-bigquery-monitoring-base

test:
	poetry run pytest

build:
	docker build -t $(IMAGE_NAME):main .
