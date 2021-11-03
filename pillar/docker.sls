docker:
  lookup:
    dockerd:
      network:
      daemon:
        experimental: true
        live-restore: true
        log-driver: json-file
        log-opts:
          max-size: 100m
          max-file: "3"
