# This file is used to load the sqlmesh configuration
from pathlib import Path

from sqlmesh.core.config import DuckDBConnectionConfig
from sqlmesh.dbt.loader import sqlmesh_config

config = sqlmesh_config(
    Path(__file__).parent,
    state_connection=DuckDBConnectionConfig(),
)
