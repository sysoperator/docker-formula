{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import containerd with context -%}
{%- from "common/vars.jinja" import
    node_roles, node_osarch
-%}

include:
  - docker.repository
{% if 'kube-cluster-member' in node_roles %}
  - crictl.install
{% endif %}

containerd:
  pkg.installed:
    - name: {{ containerd.pkg_name }}
    - version: {{ containerd.version }}
    - require:
      - pkgrepo: docker-repository
      - file: containerd-apt-pinning

containerd-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/containerd
    - contents: |
        Package: {{ containerd.pkg_name }}
        Pin: version {{ containerd.version }}
        Pin-Priority: 550
