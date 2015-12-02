# NGINX Plus Docker with Splunkforwarder

In this Dockerfile we are running NGINX Plus and Splunkforwarder, the services
are started by Supervisor.

### Setup

#### Clone the repository

```
git clone https://github.com/kmjones1979/docker-nginx-plus-splunkd
```

#### Define the Splunk server where you will be forwarding logs.

 - opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/outputs.conf

```
[tcpout]
defaultGroup = docker_splunk

[tcpout:docker_splunk]
server = 127.0.0.1:9997

[tcpout-server://127.0.0.1:9997]
```

#### Define log forwarder configuration for both error and access logs.

 - opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/inputs.conf

```
[monitor:///var/log/nginx/error.log]
sourcetype = nginx_error
disabled=false
index=main

[monitor:///var/log/nginx/access.log]
sourcetype = nginx_access
disabled=false
index=main
```

#### Copy NGINX Plus key and certificate to etc/ssl/nginx/

In order to install NGINX Plus you need to copy the nginx repo certificate
and key inside the container. We will clean this up later for security reasons.

```
$ ls -l etc/ssl/nginx
-rw-r-----@ 1 root    staff  1334 Nov 25 14:07 nginx-repo.crt
-rw-r-----@ 1 root    staff  1704 Nov 25 14:07 nginx-repo.key
```

#### Supervisor configuration

You should not need to edit the supervisord.conf however here is the proper
format for reference. This will start both the splunkforwarder along with NGINX
Plus

```
[supervisord]
nodaemon=true

[program:splunkforwarder]
command=/opt/splunkforwarder/bin/splunk start --accept-license --nodaemon --no-prompt --answer-yes

[program:nginx-plus]
command=/usr/sbin/nginx -g "daemon off;"
```

#### Build
```
docker build --no-cache -t nginx-plus-splunkd .
```

#### Run
```
docker run -i -t --name nginx-plus-splunkd -P -d nginx-plus-splunkd
```

### JSON format NGINX access logs

Included in etc/nginx/conf.d/ is a configuration file that has format for NGINX
logs in a JSON structure. This can be specified using the log_format json as shown
below.

The configuration file under etc/nginx/conf.d/json_log.conf will be included
in the main configuration using the include directive.

Then the JSON format for access_log can be used with the following syntax.

```
access_log    /var/log/nginx/json.log json;
```

You would then also need to add an input to the json log in inputs.conf.

```
[monitor:///var/log/nginx/json.log]
sourcetype = nginx_error
disabled=false
index=main
```

### Sending data directly to syslog

NGINX also supports sending log data directly to syslog. On your Splunk server
you can configure UDP data inputs and configure NGINX to transport logs to the
port of your choice as show below.
```
access_log    syslog:server=127.0.0.1:1514,tag=nginx_access main;
```
