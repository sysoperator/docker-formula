{%- set tplroot = tpldir.split('/')[0] -%}
{%- import_yaml tplroot ~ "/docker.sls" as defaults with context -%}

{{ defaults }}
