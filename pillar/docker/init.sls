{%- import_yaml 'docker/docker.sls' as defaults with context -%}
{%- import_yaml 'docker/builder.sls' as builder with context -%}
{%- import_yaml 'docker/compose.sls' as compose with context -%}
{%- import_yaml 'docker/nvidia.sls' as nvidia with context -%}

{%- set roles = salt['grains.get']('roles', []) %}

{%- do defaults.docker.lookup.update(compose) %}

{%- if 'gitlab-runner' in roles %}
  {%- do salt['defaults.merge'](defaults.docker.lookup, builder) %}
{%- endif %}

{%- if salt['grains.get']('gpus', [])|selectattr('vendor', 'equalto', 'nvidia')|list|length > 0 %}
  {%- do salt['defaults.merge'](defaults.docker.lookup, nvidia) %}
{%- endif %}

{{ defaults }}
