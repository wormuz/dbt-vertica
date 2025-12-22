{% macro vertica__generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}

-- https://discourse.getdbt.com/t/stop-schemas-from-concatenating/15180
-- This macro prevents dbt from concatenating target.schema with custom_schema_name
-- It returns only custom_schema_name if provided, otherwise returns target.schema
