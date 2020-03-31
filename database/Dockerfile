FROM adoptopenjdk:11-jre-hotspot

# Add the flyway user and step in the directory
RUN adduser --system --home /flyway --disabled-password --group flyway
WORKDIR /flyway

# Change to the flyway user
USER flyway

ENV FLYWAY_VERSION 6.3.2

RUN curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz -o flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && tar -xzf flyway-commandline-${FLYWAY_VERSION}.tar.gz --strip-components=1 \
  && rm flyway-commandline-${FLYWAY_VERSION}.tar.gz

COPY config /tmp/config
COPY sql /tmp/sql

# Add repository flyway configuration
# flyway.sqlMigrationSeparator separates Version and Description
RUN mv /flyway/conf/flyway.conf /flyway/conf/flyway.conf.original \
  && cp /tmp/config/flyway.conf /flyway/conf/flyway.conf \
  && echo 'flyway.sqlMigrationSeparator=_' >> /flyway/conf/flyway.conf

# Flatten sql directory so that database flyway_schema_history.script column
# simply reflects filename without any directory (no collisions since they must all be prefixed a different version).
RUN find /tmp/sql -name '*.sql' -exec cp {} /flyway/sql \;

ENV PATH="/flyway:${PATH}"

ENTRYPOINT ["flyway"]
CMD ["-?"]
