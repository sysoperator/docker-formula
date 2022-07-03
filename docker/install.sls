{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import docker with context -%}
{%- from tplroot ~ "/vars.jinja" import
    docker_version
with context -%}
{%- from "common/vars.jinja" import
    node_roles, node_osarch
-%}
{%- import_yaml tplroot ~ "/extensions.sls" as _ with context -%}

include:
  - debian/grub/update
  - debian/sysctl/ip-forward
{%- if 'kube-cluster-member' in node_roles %}
  {%- if salt['grains.get']('os_family') == 'Debian' %}
  - debian/policy
  {%- endif %}
  - systemd/cmd
{%- endif %}
{%- if salt['pkg.version_cmp'](docker_version, '19.03.0') >= 0 %}
  - containerd
{%- endif %}
  - .dirs
  - .repository

{%- if _['extensions']['extend'] != None %}
{{ _['extensions']|yaml(False) }}
{%- endif %}

docker.io:
  pkg.removed:
    - name: docker.io

docker:
  pkg.installed:
    - name: {{ docker.pkg_name }}
    - version: {{ docker.version }}
    - require:
      - pkg: docker.io
  {%- if salt['grains.get']('os_family') == 'Debian' %}
      - pkgrepo: docker-repository
      - file: docker-apt-pinning
  {%- endif %}
{%- if 'kube-cluster-member' in node_roles %}
  {%- if salt['grains.get']('os_family') == 'Debian' %}
      - file: policy-rc.d-enable
  {%- endif %}
    - require_in:
  {%- if salt['grains.get']('os_family') == 'Debian' %}
      - file: policy-rc.d-disable
  {%- endif %}
      - file: docker-systemd-drop-in
{%- endif %}

{%- if salt['grains.get']('os_family') == 'Debian' %}
docker-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/{{ docker.pkg_name }}
    - contents: |
        Package: {{ docker.pkg_name }}*
        Pin: version {{ docker.version }}
        Pin-Priority: 1001
{%- endif %}

{%- if node_osarch == 'amd64' %}
docker-default-kernel-settings:
  file.replace:
    - name: /etc/default/grub
    - pattern: '(^GRUB_CMDLINE_LINUX="(?!.*(cgroup_enable|swapaccount))[^"]*)'
    - repl: '\1 cgroup_enable=memory swapaccount=1'
    - require:
      - pkg: docker
    - watch_in:
      - cmd: grub-update

  {%- if (salt['pkg.version_cmp'](docker_version, '20.10.0') < 0) and salt['file.file_exists']('/sys/fs/cgroup/cgroup.controllers') %}
cgroup-v1-default:
  file.replace:
    - name: /etc/default/grub
    - pattern: '(^GRUB_CMDLINE_LINUX="(?!.*systemd\.unified_cgroup_hierarchy)[^"]*)'
    - repl: '\1 systemd.unified_cgroup_hierarchy=0'
    - watch:
      - file: docker-default-kernel-settings
    - watch_in:
      - cmd: grub-update
  {%- endif %}
{%- endif %}

/etc/docker/daemon.json:
  file.managed:
    - source: salt://{{ tplroot }}/files/docker/daemon.json.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - service: docker.service-running

{%- if 'kube-cluster-member' in node_roles %}
docker-systemd-drop-in:
  file.managed:
    - name: /etc/systemd/system/docker.service.d/override.conf
    - source: salt://{{ tplroot }}/files/systemd/system/docker.service.d/override.conf.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - file: /etc/systemd/system/docker.service.d
    - require_in:
      - service: docker.service-enabled
    - watch_in:
      - module: systemctl-reload
{%- endif %}

docker.service-enabled:
  service.enabled:
    - name: docker

docker.service-running:
  service.running:
    - name: docker
    - require:
      - sysctl: net.ipv4.ip_forward
{%- if 'kube-cluster-member' in node_roles %}
    - watch:
      - file: docker-systemd-drop-in
{%- endif %}

docker.service-reload:
  service.running:
    - name: docker
    - reload: True
    - watch:
      - file: /etc/docker/daemon.json
