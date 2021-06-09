docker:
  lookup:
    dockerd:
      #network: flannel
      daemon:
        experimental: true
        live-restore: true
        log-driver: json-file
        log-opts:
          max-size: 100m
          max-file: "3"
