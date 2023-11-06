{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import containerd with context -%}
{%- from "common/vars.jinja" import
    node_roles, node_osarch
-%}
{%- if 'kube-cluster-member' in node_roles %}
  {%- from "kubernetes/vars.jinja" import
      kubernetes_version
  -%}
{%- endif %}

include:
  - docker.repository
{%- if 'kube-cluster-member' in node_roles %}
  - crictl.install
{%- endif %}

containerd:
  pkg.installed:
    - name: {{ containerd.pkg_name }}
    - version: {{ containerd.version }}
    - require:
      - pkgrepo: docker-repository
{%- if salt['grains.get']('os_family') == 'Debian' %}
      - file: containerd-apt-pinning

containerd-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/containerd
    - contents: |
        Package: {{ containerd.pkg_name }}
        Pin: version {{ containerd.version }}
        Pin-Priority: 1001
{%- endif %}

{%- if 'kube-cluster-member' in node_roles %}
  {%- if salt['pkg.version_cmp'](kubernetes_version, 'v1.24.0') >= 0 %}
containerd.service-restart:
  service.running:
    - name: containerd

clean-disabled_plugins:
  file.replace:
    - name: /etc/containerd/config.toml
    - pattern: '^(disabled_plugins) = \[".*"\]$'
    - repl: '\1 = []'
    - watch_in:
      - service: containerd.service-restart

/etc/containerd/config.toml:
  file.blockreplace:
    - marker_start: "# START managed section"
    - marker_end: "# END managed section"
    - append_if_not_found: True
    - show_changes: True
    - watch_in:
      - service: containerd.service-restart

/etc/containerd/config.toml-accumulated:
  file.accumulated:
    - filename: /etc/containerd/config.toml
    - name: config.toml-accumulator
    - text: |
        version = 2
        
        [plugins]
        
          [plugins."io.containerd.grpc.v1.cri"]
        
            [plugins."io.containerd.grpc.v1.cri".containerd]
        
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        
                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
                  runtime_type = "io.containerd.runc.v2"
        
                  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
                    SystemdCgroup = true
    - require_in:
      - file: /etc/containerd/config.toml
  {%- endif %}
{%- endif %}
