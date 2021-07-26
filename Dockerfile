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
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid && \
  /usr/local/openresty/luajit/bin/luarocks install penlight && \
  /usr/local/openresty/luajit/bin/luarocks install lua-resty-nanoid && \
  /usr/local/openresty/luajit/bin/luarocks install tableshape && \
  /usr/local/openresty/luajit/bin/luarocks install otp

COPY . .

RUN mkdir /usr/src/app/temp
RUN chmod +x /usr/src/app/docker.sh

ENV ENVIROMENT="production"

ENTRYPOINT /usr/src/app/docker.sh lapis migrate $ENVIROMENT && lapis server $ENVIROMENT
