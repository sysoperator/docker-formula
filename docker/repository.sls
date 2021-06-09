include:
  - debian/packages/apt-transport-https
  - debian/packages/python3-apt

docker-repository:
  pkgrepo.managed:
    - name: "deb [arch={{ grains['osarch'] }}] https://download.docker.com/{{ grains['kernel']|lower }}/{{ grains['os']|lower }} {{ grains['oscodename'] }} stable"
    - file: /etc/apt/sources.list.d/docker.list
    - key_url: https://download.docker.com/{{ grains['kernel']|lower }}/{{ grains['os']|lower }}/gpg
    - require:
      - pkg: apt-transport-https
      - pkg: python3-apt
