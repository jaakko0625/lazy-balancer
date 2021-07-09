#!/bin/bash

yum update
yum install -y python3 python3-devel python3-pip
yum -y install make gcc zlib zlib-devel pcre-devel openssl openssl-devel libxslt geoip-devel gd-devel
rm -rf /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

mkdir -p /app/lazy_balancer/db
#sudo cp -r /vagrant/* /app/lazy_balancer
chown -R 1000.1000 /app
curl -fsSL https://github.com/openresty/luajit2/archive/v2.1-20190626.tar.gz -o /tmp/luajit.tar.gz 
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

cd /app/lazy_balancer
cp -r ~/lazy-balancer/* /app/lazy_balancer/
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

sed -i '/^exit 0/i supervisord -c /app/lazy_balancer/service/supervisord.conf' /etc/rc.local
echo "alias supervisoctl='supervisorctl -c /app/lazy_balancer/service/supervisord.conf'" >> ~/.bashrc
supervisord -c /app/lazy_balancer/service/supervisord.conf
