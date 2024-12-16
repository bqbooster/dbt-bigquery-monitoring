# Build args and base image
ARG build_for=linux/amd64
FROM --platform=$build_for python:3.13.1-slim-bullseye
LABEL maintainer="Kayrnt"
LABEL description="dbt development environment with BigQuery support"

# Set environment variables for proper encoding and locale
ENV PYTHONIOENCODING=utf-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install system dependencies and set locale
# Using --no-install-recommends to minimize image size
RUN apt-get update -qq \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        curl \
        ca-certificates \
        git \
        jq \
        locales \
        dumb-init \
    && echo "UTC" > /etc/localtime \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    # Install dbt completion script
    && wget -q https://raw.githubusercontent.com/dbt-labs/dbt-completion.bash/master/dbt-completion.bash -O ~/.dbt-completion.bash \
    && echo 'source ~/.dbt-completion.bash' >> ~/.bash_profile \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rust.sh \
    && sh rust.sh -y

# Add Cargo to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Update pip and install Python dependencies
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Install dbt and related tools
RUN pip install --no-cache-dir \
    sqlfluff \
    sqlfluff-templater-dbt \
    dbt-bigquery \
    'sqlmesh[github,bigquery]' \
    && rm -rf /usr/local/share/doc /root/.cache/

WORKDIR /usr/app/
ENTRYPOINT ["bash"]
