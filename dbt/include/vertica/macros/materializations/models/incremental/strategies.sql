



{% macro get_incremental_append_sql(target_relation, temp_relation, dest_columns) %}

  {{ return(adapter.dispatch('get_incremental_append_sql', 'dbt')(target_relation, temp_relation, dest_columns)) }}

{% endmacro %}


{% macro vertica__get_incremental_append_sql(target_relation, tmp_relation,dest_columns) %}

  {% do return(get_insert_into_sql(target_relation, tmp_relation,  dest_columns)) %}

{% endmacro %}
{% macro get_incremental_delete_insert_sql(arg_dict) %}

  {{ return(adapter.dispatch('get_incremental_delete_insert_sql', 'dbt')(arg_dict)) }}

{% endmacro %}


{% macro vertica__get_incremental_delete_insert_sql(arg_dict) %}

  {% do return(get_delete_insert_merge_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["unique_key"], arg_dict["dest_columns"])) %}

{% endmacro %}

{% macro get_incremental_merge_sql(arg_dict) %}

  {{ return(adapter.dispatch('get_incremental_merge_sql', 'dbt')(arg_dict)) }}

{% endmacro %}

{% macro vertica__get_incremental_merge_sql(arg_dict) %}

  {% do return(get_merge_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["unique_key"], arg_dict["dest_columns"])) %}

{% endmacro %}





{% macro get_incremental_insert_overwrite_sql(arg_dict) %}

  {{ return(adapter.dispatch('get_incremental_insert_overwrite_sql', 'dbt')(arg_dict)) }}

{% endmacro %}


{% macro vertica__get_incremental_insert_overwrite_sql(arg_dict) %}

  {% do return(get_insert_overwrite_merge_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["dest_columns"], arg_dict["predicates"])) %}

{% endmacro %}

{% macro get_incremental_update_insert_sql(arg_dict) %}

  {{ return(adapter.dispatch('get_incremental_update_insert_sql', 'dbt')(arg_dict)) }}

{% endmacro %}

{% macro vertica__get_incremental_update_insert_sql(arg_dict) %}
  {#-- Call the update+insert strategy macro #}
  {{ return(vertica__get_update_insert_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["unique_key"], arg_dict["dest_columns"], arg_dict.get("update_columns", arg_dict["dest_columns"] | map(attribute="name") | list))) }}
{% endmacro %}

{% macro vertica__get_update_insert_sql(target_relation, tmp_relation, unique_key, dest_columns, update_columns) %}
  {#-- Custom strategy: UPDATE + INSERT (like original script) instead of MERGE #}
  {#-- This matches the original script logic: UPDATE existing records, then INSERT new ones #}
  {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
  {%- if unique_key is string -%}
    {%- set unique_key_str = unique_key -%}
  {%- else -%}
    {%- set unique_key_str = unique_key | join(', ') -%}
  {%- endif -%}
  
  {#-- UPDATE existing records (matching original script lines 104-117) #}
  UPDATE {{ target_relation }} tgt
  SET 
    {% for column in update_columns -%}
      {{ adapter.quote(column) }} = src.{{ adapter.quote(column) }}
      {%- if not loop.last %}, {% endif %}
    {%- endfor %}
  FROM {{ tmp_relation }} src
  WHERE tgt.{{ adapter.quote(unique_key_str) }} = src.{{ adapter.quote(unique_key_str) }}
    AND (
      {% for column in update_columns -%}
        tgt.{{ adapter.quote(column) }} != src.{{ adapter.quote(column) }}
        {%- if not loop.last %} OR {% endif %}
      {%- endfor %}
    )
  ;

  {#-- INSERT new records (matching original script lines 119-145) #}
  INSERT INTO {{ target_relation }} ({{ dest_cols_csv }})
  SELECT 
    {% for column in dest_columns -%}
      tmp.{{ adapter.quote(column.name) }}
      {%- if not loop.last %}, {% endif %}
    {%- endfor %}
  FROM {{ tmp_relation }} tmp
  LEFT JOIN {{ target_relation }} ref
    ON ref.{{ adapter.quote(unique_key_str) }} = tmp.{{ adapter.quote(unique_key_str) }}
  WHERE ref.{{ adapter.quote(unique_key_str) }} IS NULL
  ;
{%- endmacro %}






{% macro get_incremental_default_sql(arg_dict) %}

  {{ return(adapter.dispatch('get_incremental_default_sql', 'dbt')(arg_dict)) }}

{% endmacro %}




{% macro vertica__get_incremental_default_sql(target_relation, tmp_relation,  dest_columns) %}

  {% do return(get_incremental_append_sql(target_relation, tmp_relation, dest_columns)) %}

{% endmacro %}



{% macro default__get_incremental_default_sql(arg_dict) %}

  {% do return(get_incremental_append_sql(arg_dict)) %}

{% endmacro %}


{% macro get_insert_into_sql(target_relation, temp_relation, dest_columns) %}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}

    insert into {{ target_relation }} ({{ dest_cols_csv }})
    (
        select {{ dest_cols_csv }}
        from {{ temp_relation }}
    )

{% endmacro %}
