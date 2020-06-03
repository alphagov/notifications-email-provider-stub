---
applications:
- name: notify-email-provider-stub

  memory: 256M

  buildpacks:
    - python_buildpack

  routes:
    - route: notify-email-provider-stub-{{CF_SPACE}}.cloudapps.digital

  env:
    QUEUE_PREFIX: {{CF_SPACE}}
