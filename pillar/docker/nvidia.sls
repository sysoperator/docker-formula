nvidia:
  packages:
    - name: 'nvidia-container-toolkit*'
      version: 1.16.1-1
    - name: 'libnvidia-container*'
      version: 1.16.1-1
docker:
  daemon:
    runtimes:
      nvidia:
        path: "/usr/bin/nvidia-container-runtime"
        runtimeArgs: []
