{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import docker with context -%}
{%- from tplroot ~ "/vars.jinja" import
    docker_version
with context -%}
{%- from "common/vars.jinja" import
    node_roles
-%}

extensions:
  extend:
{%- if 'kube-cluster-member' in node_roles %}
  {%- if salt['grains.get']('os_family') == 'Debian' %}
    policy-rc.d-enable:
      file.managed:
        - unless: dpkg-query -W -f="\${db:Status-Abbrev}" {{ docker.pkg_name }} 2> /dev/null | grep -q "ii"
  {%- endif %}
{%- endif %}
{%- if salt['pkg.version_cmp'](docker_version, '19.03.0') >= 0 %}
    containerd:
      pkg.installed:
        - require_in:
          - pkg: docker
{%- endif %}
