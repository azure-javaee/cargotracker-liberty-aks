# open liberty base image
FROM openliberty/open-liberty:full-java17-openj9-ubi

# Add config, app and jdbc driver
COPY --chown=1001:0 liberty/wlp/usr/servers/defaultServer/server.xml /config/server.xml
COPY --chown=1001:0 liberty/wlp/usr/servers/defaultServer/jvm.options /config/jvm.options
COPY --chown=1001:0 liberty/wlp/usr/servers/defaultServer/bootstrap.properties /config/bootstrap.properties
COPY --chown=1001:0 cargo-tracker.war /config/apps/
COPY --chown=1001:0 liberty/wlp/usr/shared/resources/postgresql.jar /opt/ol/wlp/usr/shared/resources/
COPY --chown=1001:0 liberty/wlp/usr/servers/defaultServer/applicationinsights-agent.jar /config/

# This script will add the requested XML snippets, grow image to be fit-for-purpose and apply interim fixes
RUN configure.sh
