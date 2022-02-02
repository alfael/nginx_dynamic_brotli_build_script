#!/bin/bash
export NGINX_VER=1.21.6
sudo apt-get install libpcre3-dev build-essential dpkg-dev zlib1g-dev libpcre3 unzip

wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz

tar -xzvf nginx-$NGINX_VER.tar.gz

git clone --recursive https://github.com/google/ngx_brotli.git
cd ngx_brotli/deps/brotli
git fetch git@github.com:google/brotli.git master
git merge FETCH_HEAD

cd ../../../

export NGINX_ARG=$(nginx -V 2>&1 >/dev/null | grep -o " --.*" | head -1 | xargs)

cd nginx-$NGINX_VER
./configure --with-compat "$NGINX_ARG" --add-dynamic-module=../ngx_brotli
make

sudo cp objs/ngx_http_brotli_filter_module.so  /usr/lib/nginx/modules/
sudo chmod 644 /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so
sudo cp objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
sudo chmod 644 /usr/lib/nginx/modules/ngx_http_brotli_static_module.so
