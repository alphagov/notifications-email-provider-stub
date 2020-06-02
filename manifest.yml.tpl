---
applications:
- name: notify-email-provider-stub

  memory: 256M
  instances: 1

  buildpacks:
    - python_buildpack

  routes:
    - route: notify-email-provider-stub-{{CF_SPACE}}.cloudapps.digital

  env:
    QUEUE_PREFIX: {{CF_SPACE}}
