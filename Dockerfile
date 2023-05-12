FROM centos/s2i-base-centos7

# This image provides an Apache+PHP environment for running PHP
# applications.

EXPOSE 8080
EXPOSE 8443

# Description
# This image provides an Apache 2.4 + PHP 7.3 environment for running PHP applications.
# Exposed ports:
# * 8080 - alternative port for http

ENV PHP_VERSION=7.3 \
    PHP_VER_SHORT=73 \
    NAME=php \
    PATH=$PATH:/opt/rh/rh-php73/root/usr/bin

ENV SUMMARY="Platform for building and running PHP $PHP_VERSION applications" \
    DESCRIPTION="PHP $PHP_VERSION available as container is a base platform for \
building and running various PHP $PHP_VERSION applications and frameworks. \
PHP is an HTML-embedded scripting language. PHP attempts to make it easy for developers \
to write dynamically generated web pages. PHP also offers built-in database integration \
for several commercial and non-commercial database management systems, so writing \
a database-enabled webpage with PHP is fairly simple. The most common use of PHP coding \
is probably as a replacement for CGI scripts."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Apache 2.4 with PHP ${PHP_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,${NAME},${NAME}${PHP_VER_SHORT},rh-${NAME}${PHP_VER_SHORT}" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      name="centos/${NAME}-${PHP_VER_SHORT}-centos7" \
      com.redhat.component="rh-${NAME}${PHP_VER_SHORT}-container" \
      version="${PHP_VERSION}" \
      help="For more information visit https://github.com/sclorg/s2i-${NAME}-container" \
      usage="s2i build https://github.com/sclorg/s2i-php-container.git --context-dir=${PHP_VERSION}/test/test-app centos/${NAME}-${PHP_VER_SHORT}-centos7 sample-server" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"
#install nano editor
RUN yum install -y nano
#install cron
RUN yum install -y cronie
RUN yum install -y https://www.rpmfind.net/linux/epel/7/x86_64/Packages/l/libc-client-2007f-16.el7.x86_64.rpm
# Install Apache httpd and PHP
RUN yum install -y rh-php73-php-pear rh-php73-php-devel
RUN yum install -y centos-release-scl && \
    INSTALL_PKGS="rh-php73 rh-php73-php rh-php73-php-mysqlnd rh-php73-php-pgsql rh-php73-php-bcmath \
                  rh-php73-php-gd rh-php73-php-intl rh-php73-php-ldap rh-php73-php-mbstring rh-php73-php-pdo \
                  rh-php73-php-process rh-php73-php-soap rh-php73-php-opcache rh-php73-php-xml \
                  rh-php73-php-gmp rh-php73-php-pecl-apcu rh-php73-php-devel httpd24-mod_ssl" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS --nogpgcheck && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'
RUN yum update -y
RUN yum install -y epel-release
RUN yum install -y libsodium libsodium-devel
RUN yum install -y php-pecl-libsodium
RUN yum install -y sclo-php73-php-imap
RUN curl http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/r/re2c-0.14.3-2.el7.x86_64.rpm --output re2c-0.14.3-2.el7.x86_64.rpm
RUN rpm -Uvh re2c-0.14.3-2.el7.x86_64.rpm
ENV PHP_CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/php/ \
    APP_DATA=${APP_ROOT}/src \
    PHP_DEFAULT_INCLUDE_PATH=/opt/rh/rh-php73/root/usr/share/pear \
    PHP_SYSCONF_PATH=/etc/opt/rh/rh-php73 \
    PHP_HTTPD_CONF_FILE=rh-php73-php.conf \
    HTTPD_CONFIGURATION_PATH=${APP_ROOT}/etc/conf.d \
    HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
    HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
    HTTPD_VAR_RUN=/var/run/httpd \
    HTTPD_DATA_PATH=/var/www \
    HTTPD_DATA_ORIG_PATH=/opt/rh/httpd24/root/var/www \
    HTTPD_VAR_PATH=/opt/rh/httpd24/root/var \
    SCL_ENABLED=rh-php73
#install libsodium
RUN pecl install libsodium
RUN echo "extension=libsodium.so" >> /etc/php.ini
# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

#fix permission 
RUN chmod +x /usr/libexec/container-setup
RUN chmod +x /usr/libexec/s2i/usage
RUN chmod +x /usr/libexec/s2i/assemble
RUN chmod +x /usr/libexec/s2i/save-artifacts
RUN chmod +x /usr/libexec/s2i/run
# Reset permissions of filesystem to default values
RUN /usr/libexec/container-setup && rpm-file-permissions

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
