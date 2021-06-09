{% from "containerd/map.jinja" import containerd with context %}

include:
  - docker.repository
  - crictl.install

containerd:
  pkg.installed:
    - name: {{ containerd.pkg_name }}
    - version: {{ containerd.version }}
    - require:
      - pkgrepo: docker-repository
      - file: containerd-apt-pinning
    - require_in:
      - file: crictl

containerd-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/containerd
    - contents: |
        Package: {{ containerd.pkg_name }}
        Pin: version {{ containerd.version }}
        Pin-Priority: 550
