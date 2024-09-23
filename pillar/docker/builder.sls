docker:
  daemon:
    builder:
      gc:
        enabled: True
        defaultKeepStorage: "10GB"
        policy:
          - keepStorage: "10GB"
            filter:
              - "unused-for=120h"
          - keepStorage: "50GB"
            filter:
              - "unused-for=240h"
          - keepStorage: "100GB"
            all: True
