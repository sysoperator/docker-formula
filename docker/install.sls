{% from "docker/map.jinja" import docker with context %}
{% from "docker/vars.jinja" import
   docker_version
with context %}
{% from "common/vars.jinja" import
    node_roles, node_osarch
with context %}

include:
  - debian/grub/update
  - debian/sysctl/ip-forward
{% if 'kube-cluster-member' in node_roles %}
  - debian/policy
  - systemd/cmd
{% endif %}
  - containerd
  - .dirs
  - .repository

extend:
{% if 'kube-cluster-member' in node_roles %}
  policy-rc.d-enable:
    file.managed:
      - unless: dpkg-query -W -f="\${db:Status-Abbrev}" {{ docker.pkg_name }} 2> /dev/null | grep -q "ii"
{% endif %}
  containerd:
    pkg.installed:
      - require_in:
        - pkg: docker

docker.io:
  pkg.removed:
    - name: docker.io

docker:
  pkg.installed:
    - name: {{ docker.pkg_name }}
    - version: {{ docker.version }}
    - require:
      - pkg: docker.io
      - pkgrepo: docker-repository
      - file: docker-apt-pinning
{% if 'kube-cluster-member' in node_roles %}
      - file: policy-rc.d-enable
    - require_in:
      - file: policy-rc.d-disable
      - file: docker-systemd-drop-in
{% endif %}

docker-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/{{ docker.pkg_name }}
    - contents: |
        Package: {{ docker.pkg_name }}*
        Pin: version {{ docker.version }}
        Pin-Priority: 550

{% if node_osarch == 'amd64' %}
docker-default-kernel-settings:
  file.replace:
    - name: /etc/default/grub
    - pattern: '(^GRUB_CMDLINE_LINUX="(?!.*(cgroup_enable|swapaccount))[^"]*)'
    - repl: '\1 cgroup_enable=memory swapaccount=1'
    - require:
      - pkg: docker
    - watch_in:
      - cmd: grub-update

  {% if (salt['pkg.version_cmp'](docker_version, '20.10.0') < 0) and salt['file.file_exists']('/sys/fs/cgroup/cgroup.controllers') %}
cgroup-v1-default:
  file.replace:
    - name: /etc/default/grub
    - pattern: '(^GRUB_CMDLINE_LINUX="(?!.*systemd\.unified_cgroup_hierarchy)[^"]*)'
    - repl: '\1 systemd.unified_cgroup_hierarchy=0'
    - watch:
      - file: docker-default-kernel-settings
    - watch_in:
      - cmd: grub-update
  {% endif %}
{% endif %}

/etc/docker/daemon.json:
  file.managed:
    - source: salt://docker/files/docker/daemon.json.j2
    - template: jinja
    - require:
      - service: docker.service-running

{% if 'kube-cluster-member' in node_roles %}
docker-systemd-drop-in:
  file.managed:
    - name: /etc/systemd/system/docker.service.d/override.conf
    - source: salt://docker/files/systemd/system/docker.service.d/override.conf.j2
    - template: jinja
    - require:
      - file: /etc/systemd/system/docker.service.d
    - require_in:
      - service: docker.service-enabled
    - watch_in:
      - module: systemctl-reload
{% endif %}

docker.service-enabled:
  service.enabled:
    - name: docker

docker.service-running:
  service.running:
    - name: docker
    - require:
      - sysctl: net.ipv4.ip_forward
{% if 'kube-cluster-member' in node_roles %}
    - watch:
      - file: docker-systemd-drop-in
{% endif %}

docker.service-reload:
  service.running:
    - name: docker
    - reload: True
    - watch:
      - file: /etc/docker/daemon.json
