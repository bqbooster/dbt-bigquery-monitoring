{% macro top_sum(array) %}
(SELECT APPROX_TOP_SUM(c.value, c.count, 100) FROM UNNEST({{ array }}) c)
{% endmacro %}
