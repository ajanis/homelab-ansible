# rsyslog, telegraf and ansible configuration for parsing docker container logs

This setup assumes docker containers are running via systemd using ansible-docker role

## docker container setup

- docker container should log to journald
- This happens automatically if you use ansible-docker role

## rsyslog setup

### create rsyslog configuration file

```
# /etc/rsyslog.d/20-docker.conf
if $programname == 'automation_obj_detection' then /var/log/docker/automation_obj_detection.log
```

### ansible setup

#### Template

Create a template with something similar to the following. If using ansible-docker role, this could
be wrapped in a loop or (imo, better) installed via a looping task.

```
# /etc/rsyslog.d/20-{{ item.container_name }}.conf
if $programname == '{{ item.container_name }}' then /var/log/docker/20-{{ item.container_name }}.log
```

#### Task

```yaml
# main.yml or other task
- name: Configure rsyslog files for containers
  ansible.builtin.include_tasks:
    file: docker-rsyslog.yml
  loop: "{{ docker_compose_projects }}"
  loop_control:
    loop_var: project_item
```

```yaml
# docker-rsyslog.yml
- name: Create systemd files for docker-compose services
  template:
    src: docker-rsyslog.conf.j2
    dest:
      "{% if item.value.container_name is defined %}/var/rsyslog.d/20-{{ item.value.container_name
      }}.conf{% else %}/etc/rsyslog.d/20-{{ project_item.project_name }}-{{ item.key }}.conf{% endif
      %}"
    mode: 0755
  loop: "{{ project_item.definition.services|dict2items }}"
  register: docker_compose_service
  loop_control:
    label: "{{ item.key }}"
```

## telegraf setup

### ansible-telegraf role config

This example uses home assistant object detection container

```yaml
telegraf_plugins_extra:
  - name: logparser
    options:
      files:
        - "/var/log/docker/automation_object_detection.log
      from_beginning: "false"
      grok:
        patterns:
          - '^%{TIMESTAMP_ISO8601:timestamp}.*Detection Complete.*"package": "%{NOTSPACE:package}".*"name": "%{NOTSPACE:detector}".*"duration": %{NUMBER:duration}.*"detections": %{NUMBER:detections}.*("device".*"Path":"%{NOTSPACE:device}").*$'
          - '^%{TIMESTAMP_ISO8601:timestamp}.*HTTP Request.*"took": %{NUMBER:duration}.*"remote": "%{HOSTPORT:source}".*$'
        measurement: docker_automation_obj_detection
```

### raw telegraf.conf file

```
[[inputs.logparser]]
    files = [ '/var/log/docker/automation_obj_detection.log' ]
    from_beginning = false
    [inputs.logparser.grok]
      patterns = [ '^%{TIMESTAMP_ISO8601:timestamp}.*Detection Complete.*"package": "%{NOTSPACE:package}".*"name": "%{NOTSPACE:detector}".*"duration": %{NUMBER:duration}.*"detections": %{NUMBER:detections}.*("device".*"Path":"%{NOTSPACE:device}").*$', '^%{TIMESTAMP_ISO8601:timestamp}.*HTTP Request.*"took": %{NUMBER:duration}.*"remote": "%{HOSTPORT:source}".*$' ]
      measurement = "docker_automation_obj_detection"
```
