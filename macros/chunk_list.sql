{#
  Split a sequence into consecutive chunks of at most `chunk_size` items.

  Example:
    chunk_list(['a', 'b', 'c', 'd'], 2) → [['a', 'b'], ['c', 'd']]
#}
{% macro chunk_list(values, chunk_size) %}
  {% set chunk_size_n = chunk_size | int %}
  {% if chunk_size_n <= 0 %}
    {% do exceptions.raise_compiler_error(
      "chunk_list chunk_size must be a positive integer, got: " ~ chunk_size
    ) %}
  {% endif %}

  {% set chunks = [] %}
  {% set values_list = values | list %}
  {% for i in range(0, values_list | length, chunk_size_n) %}
    {% do chunks.append(values_list[i:i + chunk_size_n]) %}
  {% endfor %}
  {{ return(chunks) }}
{% endmacro %}
