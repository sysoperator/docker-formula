{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import docker with context -%}
{%- from "common/vars.jinja" import
    node_osarch, node_kernel
-%}

{%- if salt['grains.get']('os_family') == 'Debian' %}
include:
  - debian/packages/apt-transport-https
  - debian/packages/python3-apt

docker-repository:
  pkgrepo.managed:
    - name: "deb [arch={{ node_osarch }}] https://download.docker.com/{{ node_kernel }}/{{ grains['os']|lower }} {{ grains['oscodename'] }} stable"
    - file: /etc/apt/sources.list.d/docker.list
    - key_url: https://download.docker.com/{{ node_kernel }}/{{ grains['os']|lower }}/gpg
    - require:
      - pkg: apt-transport-https
      - pkg: python3-apt
{%- endif %}
