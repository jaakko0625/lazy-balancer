#!/bin/bash

yum update -y
yum -y install epel-release -y
yum install -y python3 python3-devel python3-pip
yum -y install tar make gcc zlib zlib-devel pcre-devel openssl openssl-devel libxslt-devel geoip-devel gd-devel
rm -rf /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

mkdir -p /app/lazy_balancer/db
#sudo cp -r /vagrant/* /app/lazy_balancer
chown -R 1000.1000 /app
tar zxf luajit* -C /tmp && cd /tmp/luajit2-2.1-20190626
make && make install
export LUAJIT_INC=/usr/local/include/luajit-2.1
export LUAJIT_LIB=/usr/local/lib
ln -sf luajit /usr/local/bin/luajit
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig
tar -zxf ~/lazy-balancer/tengine* -C /tmp && cd /tmp/tengine-2.3.3
./configure --user=www-data --group=www-data --prefix=/etc/nginx --sbin-path=/usr/sbin \
      --error-log-path=/var/log/nginx/error.log --conf-path=/etc/nginx/nginx.conf --pid-path=/run/nginx.pid \
      --with-http_secure_link_module \
      --with-http_image_filter_module \
      --with-http_random_index_module \
      --with-threads \
      --with-http_ssl_module \
      --with-http_sub_module \
      --with-http_stub_status_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_realip_module \
      --with-compat \
      --with-file-aio \
      --with-http_dav_module \
      --with-http_degradation_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_xslt_module \
      --with-http_auth_request_module \
      --with-http_addition_module \
      --with-http_v2_module \
      --add-module=./modules/ngx_http_upstream_check_module \
      --add-module=./modules/ngx_http_upstream_session_sticky_module \
      --add-module=./modules/ngx_http_upstream_dynamic_module \
      --add-module=./modules/ngx_http_upstream_consistent_hash_module \
      --add-module=./modules/ngx_http_upstream_dyups_module \
      --add-module=./modules/ngx_http_user_agent_module \
      --add-module=./modules/ngx_http_proxy_connect_module \
      --add-module=./modules/ngx_http_concat_module \
      --add-module=./modules/ngx_http_footer_filter_module \
      --add-module=./modules/ngx_http_sysguard_module \
      --add-module=./modules/ngx_http_slice_module \
      --add-module=./modules/ngx_http_lua_module \
      --add-module=./modules/ngx_http_reqstat_module \
      --with-http_geoip_module=dynamic \
      --with-stream
make && make install
mkdir -p /etc/nginx/conf.d

cp -r ~/lazy-balancer/* /app/lazy_balancer/
cd /app/lazy_balancer
rm -rf /etc/nginx/nginx.conf
cp -rf resource/nginx/nginx.conf.default /etc/nginx/nginx.conf
cp -f resource/nginx/default.* /etc/nginx/ 
/usr/sbin/groupadd -f www-data
/usr/sbin/useradd -g www-data www-data

pip3 install pip --upgrade
pip3 install -r requirements.txt --upgrade

rm -rf db/*
rm -rf */migrations/00*.py
python manage.py makemigrations --noinput
python manage.py migrate --run-syncdb
python manage.py makemigrations --noinput 2>/dev/null
python manage.py migrate --run-syncdb 

cat >> /etc/rc.d/rc.local <<EOF
supervisord -c /app/lazy_balancer/service/supervisord.conf
EOF
chmod +x /etc/rc.d/rc.local
supervisord -c /app/lazy_balancer/service/supervisord.conf
