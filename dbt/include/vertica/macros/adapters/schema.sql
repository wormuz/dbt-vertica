{% macro vertica__create_schema(relation) -%}
  {# Completely disable schema creation - always return empty string #}
  {{ return('') }}
{% endmacro %}


{% macro vertica__drop_schema(relation) -%}
  {# Disable schema dropping through dbt #}
  {{ return('') }}
{% endmacro %}