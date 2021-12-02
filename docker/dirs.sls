{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import docker with context -%}

/etc/systemd/system/docker.service.d:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True
