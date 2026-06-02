{#
  Limit incremental insert_overwrite models partitioned on minute (hour granularity)
  to partitions at or after the current max partition.
#}
{% macro compute_incremental_minute_filter(timestamp_column='minute') %}
  {% if is_incremental() %}
  WHERE {{ timestamp_column }} >= {{ get_partition_timestamp() }}
  {% endif %}
{% endmacro %}
