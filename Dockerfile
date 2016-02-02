FROM centos:centos7

MAINTAINER Kevin Jones "kevin@nginx.com"

# set environment variables
ENV SPLUNK_FORWARDER_VERSION 6.2.2
ENV SPLUNK_FORWARDER_BUILD 255606
ENV SPLUNK_FORWARDER_CENTOS_URL https://download.splunk.com/products/splunk/releases/${SPLUNK_FORWARDER_VERSION}/universalforwarder/linux/splunkforwarder-${SPLUNK_FORWARDER_VERSION}-${SPLUNK_FORWARDER_BUILD}-linux-2.6-x86_64.rpm

# install epel-release & dependencies / update
RUN yum install -y epel-release wget
RUN yum update -y

# install splunkforwarder
RUN curl --show-error ${SPLUNK_FORWARDER_CENTOS_URL} -o splunkforwarder.rpm
RUN rpm -i splunkforwarder.rpm && rm splunkforwarder.rpm

# copy splunk configuration
COPY opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/inputs.conf /opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/inputs.conf
COPY opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/outputs.conf /opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/local/outputs.conf

# install supervisord
RUN yum -y install python-setuptools
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor

# copy supervisor configuration
COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Download certificate and key from the customer portal https://cs.nginx.com
# # and copy to the build context
RUN mkdir -p /etc/ssl/nginx
ADD etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/
ADD etc/ssl/nginx/nginx-repo.key /etc/ssl/nginx/

# Get other files required for installation
RUN wget -q -O /etc/ssl/nginx/CA.crt https://cs.nginx.com/static/files/CA.crt
RUN wget -q -O /etc/yum.repos.d/nginx-plus-7.repo https://cs.nginx.com/static/files/nginx-plus-7.repo

# Install NGINX Plus
RUN yum install -y nginx-plus-extras

# forward request logs to docker log collector
#RUN ln -sf /dev/stdout /var/log/nginx/access.log
#RUN ln -sf /dev/stderr /var/log/nginx/error.log

# copy static Nginx Plus files
COPY etc/nginx /etc/nginx

# clean up keys inside image
RUN rm -f /etc/ssl/nginx/nginx-repo.crt
RUN rm -f /etc/ssl/nginx/nginx-repo.key

# clean up
RUN yum clean all

EXPOSE 80 443 8080 8089

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
