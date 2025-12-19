{% macro generate_schema_name(custom_schema_name, node) %}
    {{ custom_schema_name }}
{% endmacro %}

-- https://discourse.getdbt.com/t/stop-schemas-from-concatenating/15180
