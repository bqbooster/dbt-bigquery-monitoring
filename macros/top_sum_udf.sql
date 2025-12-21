{% macro top_sum(array) %}
(SELECT APPROX_TOP_SUM(c.value, CAST(c.sum AS INT64), 100) FROM UNNEST({{ array }}) c)
{% endmacro %}

{% macro top_sum_from_count(array) %}
(SELECT APPROX_TOP_SUM(c.value, CAST(c.count AS INT64), 100) FROM UNNEST({{ array }}) c)
{% endmacro %}