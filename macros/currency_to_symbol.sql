{#-- macro to transform an ISO 4217 (currency) to currency symbol #}
{% macro currency_to_symbol(currency_field) -%}
CASE {{ currency_field }}
WHEN 'USD' THEN '$'
WHEN 'EUR' THEN '€'
WHEN 'JPY' THEN '¥'
WHEN 'AUD' THEN 'A$'
WHEN 'BRL' THEN 'R$'
WHEN 'CAD' THEN 'C$'
WHEN 'HKD' THEN 'HK$'
WHEN 'INR' THEN '₹'
WHEN 'IDR' THEN 'Rp'
WHEN 'ILS' THEN '₪'
WHEN 'MXN' THEN 'Mex$'
WHEN 'NZD' THEN 'NZ$'
WHEN 'GBP' THEN '£'
ELSE {{ currency_field }}
END
{%- endmacro %}
