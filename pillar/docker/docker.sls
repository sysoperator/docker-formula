docker:
  lookup:
    docker:
      network: bridge
      dns:
      daemon:
        experimental: true
        live-restore: true
{%- if salt['grains.get']('os_family') == 'Debian' %}
        log-driver: json-file
        log-opts:
          max-size: 100m
          max-file: "3"
        exec-opts:
          - "native.cgroupdriver=systemd"
{%- endif %}
