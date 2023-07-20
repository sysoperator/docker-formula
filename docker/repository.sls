{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import docker with context -%}
{%- from "common/vars.jinja" import
    node_osarch, node_kernel_lower
-%}

{%- if salt['grains.get']('os_family') == 'Debian' %}
include:
  - debian/packages/apt-transport-https
  - debian/packages/python3-apt
{%- endif %}

docker-repository:
  pkgrepo.managed:
{%- if salt['grains.get']('os_family') == 'Debian' %}
    - name: "deb [arch={{ node_osarch }}] https://download.docker.com/{{ node_kernel_lower }}/{{ grains['os']|lower }} {{ grains['oscodename'] }} stable"
    - file: /etc/apt/sources.list.d/docker.list
    - key_url: https://download.docker.com/{{ node_kernel_lower }}/{{ grains['os']|lower }}/gpg
    - require:
      - pkg: apt-transport-https
      - pkg: python3-apt
{%- elif salt['grains.get']('os_family') == 'RedHat' %}
    - name: docker-ce-stable
    - humanname: 'Docker CE Stable - $basearch'
    - baseurl: 'https://download.docker.com/linux/centos/$releasever/$basearch/stable'
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: https://download.docker.com/linux/centos/gpg
{%- endif %}
