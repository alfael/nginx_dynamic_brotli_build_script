#!/bin/bash
export NGINX_VER=1.26.0
echo "[*] Installing deps...."
sudo apt-get install libpcre3-dev build-essential dpkg-dev zlib1g-dev libpcre3 unzip wget git gcc cmake libpcre3 zlib1g zlib1g-dev openssl libssl-dev gnupg2

echo "[*] Cleaning existing build files ..."
if [ -d "nginx-$NGINX_VER" ]; then
rm -rf nginx-$NGINX_VER
fi
if [ -d "ngx_brotli" ]; then
rm -rf ngx_brotli
fi


echo "[*] Check nginx-$NGINX_VER.tar.gz file..."
if [ ! -f "nginx-$NGINX_VER.tar.gz" ]; then
echo "[*] FIle not exist, download it..."
wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
fi

echo "[*] Unzip it ..."
tar -xzvf nginx-$NGINX_VER.tar.gz

echo "[*] Clone ngx_brotli project"
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli.git
cd ngx_brotli/deps/brotli
mkdir out && cd out
echo "[*] Build brotli..."
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
cmake --build . --config Release --target brotlienc

cd ../../../..

export NGINX_ARG=$(nginx -V 2>&1 >/dev/null | grep -o " --.*" | head -1 | xargs)

cd nginx-$NGINX_VER
echo "[*] Build nginx brotli module ..."
./configure --with-compat "$NGINX_ARG" --add-dynamic-module=../ngx_brotli
make

echo "[*] Install nginx brotli module to /usr/lib/nginx/modules/ ...."
sudo cp objs/ngx_http_brotli_filter_module.so  /usr/lib/nginx/modules/
sudo chmod 644 /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so
sudo cp objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
sudo chmod 644 /usr/lib/nginx/modules/ngx_http_brotli_static_module.so

cd ../

echo "[*] Cleaning build files"
if [ -d "nginx-$NGINX_VER" ]; then
rm -rf nginx-$NGINX_VER
fi
if [ -d "ngx_brotli" ]; then
rm -rf ngx_brotli
fi

if [ -f "nginx-$NGINX_VER.tar.gz" ]; then
rm nginx-$NGINX_VER.tar.gz
fi

echo "[*] That's all ! just enable it  in /etc/nginx/nginx.conf"
echo ""
echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;"
echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;"
echo "brotli on;"
echo "brotli_comp_level 3;"
echo "brotli_buffers 32 8k;"
echo "brotli_min_length 100;"
echo "brotli_static on;"
echo "brotli_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;"


