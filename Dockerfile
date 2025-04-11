FROM kong:3.4

USER root

# Copy plugin to Kong Lua path
COPY plugins/guard /usr/local/share/lua/5.1/kong/plugins/guard/

# Copy config files
COPY kong.conf /etc/kong/kong.conf
COPY kong.yml /kong.yml

# Set plugin path
ENV KONG_PLUGINS=bundled,guard

EXPOSE 8000 8443 8001 8444

USER kong
