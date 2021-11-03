{% from "docker/map.jinja" import docker with context %}
{% from "common/vars.jinja" import
    node_roles, node_osarch
with context %}

include:
{% if 'kube-cluster-member' in node_roles %}
  - debian/policy
  - debian/grub/update
  - debian/sysctl/ip-forward
  - systemd/cmd
{% endif %}
  - .repository
  - containerd

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
      - file: docker-systemd-unit-file
{% endif %}

docker-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/{{ docker.pkg_name }}
    - contents: |
        Package: {{ docker.pkg_name }}*
        Pin: version {{ docker.version }}
        Pin-Priority: 550

{% if node_osarch == 'amd64' %}
docker-kernel-settings:
  file.replace:
    - name: /etc/default/grub
    - pattern: '(^GRUB_CMDLINE_LINUX="(?!.*(cgroup_enable|swapaccount))[^"]*)'
    - repl: '\1 cgroup_enable=memory swapaccount=1'
    - require:
      - pkg: docker
    - watch_in:
      - cmd: grub-update
{% endif %}

docker-daemon.json:
  file.managed:
    - name: /etc/docker/daemon.json
    - source: salt://docker/files/docker/daemon.json.j2
    - template: jinja
    - require:
      - service: docker-service-running

{% if 'kube-cluster-member' in node_roles %}
docker-systemd-unit-file:
  file.managed:
    - name: /etc/systemd/system/docker.service
    - source: salt://docker/files/systemd/system/docker.service.j2
    - template: jinja
    - require_in:
      - service: docker-service-enable
    - watch_in:
      - module: systemctl-reload
{% endif %}

docker-service-enable:
  service.enabled:
    - name: docker

docker-service-running:
  service.running:
    - name: docker
{% if 'kube-cluster-member' in node_roles %}
    - require:
      - sysctl: net.ipv4.ip_forward
    - watch:
      - file: docker-systemd-unit-file

docker-service-reload:
  service.running:
    - name: docker
    - reload: True
    - watch:
      - file: docker-daemon.json
{% endif %}
