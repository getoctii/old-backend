FROM openresty/openresty:alpine-fat

WORKDIR /usr/src/app

RUN apk add openssl openssl-dev git argon2 argon2-dev

RUN \
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-http && \
  /usr/local/openresty/luajit/bin/luarocks install inspect && \
  /usr/local/openresty/luajit/bin/luarocks install lua-cjson && \
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt && \
  /usr/local/openresty/luajit/bin/luarocks install lapis && \
  /usr/local/openresty/luajit/bin/luarocks install argon2-ffi && \
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-uuid && \
  /usr/local/openresty/luajit/bin/luarocks install luaossl && \
  /usr/local/openresty/luajit/bin/luarocks install array && \
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid

COPY . .

RUN mkdir /usr/src/app/temp

CMD lapis migrate && lapis server