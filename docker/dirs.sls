{% from "docker/map.jinja" import docker with context %}

docker-systemd-drop-in-dir:
  file.directory:
    - name: /etc/systemd/system/docker.service.d
    - dir_mode: 755
    - user: root
    - makedirs: True
