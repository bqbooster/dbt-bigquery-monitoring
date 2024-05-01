SHELL := /bin/bash

.PHONY: activate_environment setup_environment run

all: run

activate_environment:
	conda activate dbt-bigquery-monitoring-parser

setup_environment:
	conda create -n dbt-bigquery-monitoring-parser python=3.11 &&\
	conda activate dbt-bigquery-monitoring-parser &&\
	pip install beautifulsoup4 jinja2 requests

run:
	python documentation_parser.py
