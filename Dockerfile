FROM ubuntu:14.04

MAINTAINER Seito Tomioka <tomioka.s@wingarc.com>

# set up environment
RUN \
  apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install -y libtool && \
	apt-get install -y libxml2 && \
	apt-get install -y libxml2-dev && \
	apt-get install -y libxml2-utils && \
	apt-get install -y libaprutil1 && \
	apt-get install -y libaprutil1-dev && \
	apt-get install -y autoconf && \
	apt-get install -y apache2-dev && \
	apt-get install -y git && \
	apt-get install -y wget

WORKDIR /tmp

# install and build mod_securty
RUN \
#  cd /tmp && \
	git clone https://github.com/SpiderLabs/ModSecurity.git mod_security && \
	cd mod_security && \
	./autogen.sh && \
	./configure --enable-standalone-module && \
	make

# install and build nginx
RUN \
  useradd -s /sbin/nologin nginx && \
	wget http://www.nginx.org/download/nginx-1.9.9.tar.gz && \
	tar -xvpzf nginx-1.9.9.tar.gz && \
  cd nginx-1.9.9 && \
  ./configure \
    --add-module=../mod_security/nginx/modsecurity \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-http_v2_module \
    --with-ipv6 && \
  make && make install && \
  mkdir /var/cache/nginx && \
  rm -rf /tmp/*

WORKDIR /root

COPY init.d/nginx /etc/init.d/nginx
COPY logrotate.d/nginx /etc/logrotate.d/nginx

RUN chmod +x /etc/init.d/nginx

VOLUME ["/etc/nginx/conf.d", "/var/log/nginx"]

CMD ["nginx", "-g", "daemon off;"]
