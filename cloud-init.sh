#!/bin/sh

# Function to grab SSM parameters
aws_get_parameter() {
    aws ssm --region ${REGION} get-parameter \
        --name "${PARAMETER_PATH}/$1" \
        --with-decryption \
        --output text \
        --query Parameter.Value 2>/dev/null
}

# Install Cloudwatch Agent
curl -sL https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -o amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Pull config and start Cloudwatch Agent
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${CLOUDWATCH_SYSTEM_CONFIG} -s
amazon-cloudwatch-agent-ctl -a append-config -m ec2 -c ssm:${CLOUDWATCH_KONG_CONFIG} -s

# Enable auto updates
echo "Enabling auto updates"
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true \
    | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# Installing decK
# https://github.com/hbagdi/deck
curl -sL https://github.com/hbagdi/deck/releases/download/v${DECK_VERSION}/deck_${DECK_VERSION}_linux_amd64.tar.gz \
    -o deck.tar.gz
tar zxf deck.tar.gz deck
sudo mv deck /usr/local/bin
sudo chown root:kong /usr/local/bin/deck
sudo chmod 755 /usr/local/bin/deck

# Install Kong
echo "Installing Kong"
EE_LICENSE=$(aws_get_parameter ee/license)
EE_CREDS=$(aws_get_parameter ee/bintray-auth)
if [ "$EE_LICENSE" != "" ] && [ "$EE_LICENSE" != "placeholder" ]; then
    curl -sL "${EE_PKG}" -u $EE_CREDS -o kong.deb

    if [ ! -f kong.deb ]; then
        echo "Error: Enterprise edition download failed, aborting."
        exit 1
    fi
    dpkg -i kong.deb

    cat <<EOF > /etc/kong/license.json
$EE_LICENSE
EOF
    chown root:kong /etc/kong/license.json
    chmod 640 /etc/kong/license.json
else
    curl -sL "${CE_PKG}" -o kong.deb
    dpkg -i kong.deb
fi

# Setup database

# echo "Setting up Kong database"
# PGPASSWORD=$(aws_get_parameter "db/password/master")
# DB_HOST=$(aws_get_parameter "db/host")
# DB_NAME=$(aws_get_parameter "db/name")
# DB_PASSWORD=$(aws_get_parameter "db/password")
# export PGPASSWORD
#
# RESULT=$(psql --host $DB_HOST --username root \
#     --tuples-only --no-align postgres \
#     <<EOF
# SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'
# EOF
# )
#
# if [ $? != 0 ]; then
#     echo "Error: Database connection failed, please configure manually"
#     exit 1
# fi
#
# echo $RESULT | grep -q 1
# if [ $? != 0 ]; then
#     psql --host $DB_HOST --username root postgres <<EOF
# CREATE USER ${DB_USER} WITH PASSWORD '$DB_PASSWORD';
# GRANT ${DB_USER} TO root;
# CREATE DATABASE $DB_NAME OWNER = ${DB_USER};
# EOF
# fi
# unset PGPASSWORD

# Setup Configuration file
cat <<EOF > /etc/kong/kong.conf
# PATH: /etc/kong/kong.conf

database = off

declarative_config = kong.yml

# Load balancer headers
real_ip_header = X-Forwarded-For
trusted_ips = 0.0.0.0/0

# SSL termination is performed by load balancers
proxy_listen = 0.0.0.0:8000
# For /status to load balancers
admin_listen = 127.0.0.1:8001

# Disable headers
headers = off

# Increase request body size to 16 megabytes
nginx_http_client_body_buffer_size = 16m

# Avoid checking client body size
nginx_http_client_max_body_size = 0

# Disable proxy response buffering and stream directly to the client
nginx_proxy_proxy_buffering = off

# extend default "combined" format by adding perf timing. Also - trying to get request IDs from headers, e.g., x-vercel-id
# see https://docs.nginx.com/nginx/admin-guide/monitoring/logging/ for config parameters
nginx_http_log_format=combined_with_perf_data '\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent "\$http_referer" "\$http_user_agent" rt="\$request_time" uct="\$upstream_connect_time" uht="\$upstream_header_time" urt="\$upstream_response_time"'
nginx_proxy_access_log=logs/access_timing.log combined_with_perf_data

EOF

chmod 640 /etc/kong/kong.conf
chgrp kong /etc/kong/kong.conf

cat <<EOF > /etc/kong/kong.yml
_format_version: "1.1"

services:
- connect_timeout: 60000
  host: 127.0.0.1
  name: kong-admin-api
  port: 8001
  protocol: http
  read_timeout: 60000
  retries: 5
  write_timeout: 60000
  routes:
  - hosts:
    - '*.saage.io'
    name: kong-admin-route
    paths:
    - /kong-admin-api
    path_handling: v0
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    strip_path: true
    https_redirect_status_code: 426
    request_buffering: true
    response_buffering: true


- connect_timeout: 60000
  host: ${ORCH_HOST}
  name: orchestrator-healthcheck
  path: /health
  port: 8085
  protocol: http
  read_timeout: 60000
  retries: 5
  write_timeout: 60000
  routes:
  - name: orchestrator-healthcheck
    paths:
    - /health
    path_handling: v0
    preserve_host: false
    protocols:
    - http
    regex_priority: 0
    strip_path: true
    https_redirect_status_code: 426
    request_buffering: true
    response_buffering: true

- connect_timeout: 60000
  host: localhost
  name: loadbalancer-healthcheck
  path: /status
  port: 8001
  protocol: http
  read_timeout: 60000
  retries: 5
  write_timeout: 60000
  routes:
  - name: loadbalancer-healthcheck
    methods:
    - HEAD
    - GET
    paths:
    - /status
    path_handling: v0
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    strip_path: true
    https_redirect_status_code: 426
    request_buffering: true
    response_buffering: true


- connect_timeout: 60000
  host: ${ORCH_HOST}
  name: orchestrator
  path: /
  port: 8085
  protocol: http
  read_timeout: 60000
  retries: 5
  write_timeout: 60000
  routes:
  - name: orchestrator
    paths:
    - /
    path_handling: v0
    preserve_host: false
    protocols:
    - http
    regex_priority: 0
    strip_path: true
    https_redirect_status_code: 426
    request_buffering: true
    response_buffering: true
plugins:
- name: basic-auth
  service: orchestrator
  config:
    hide_credentials: false
  enabled: true

consumers:
- username: user
  basicauth_credentials:
  - consumer: user
    username: saage-orchestrator
    password: saage-orchestrator

EOF
chmod 640 /etc/kong/kong.yml
chgrp kong /etc/kong/kong.yml

if [ "$EE_LICENSE" != "placeholder" ]; then
    cat <<EOF >> /etc/kong/kong.conf

# Enterprise Edition Settings
# SSL terminiation is performed by load balancers
admin_gui_listen  = 0.0.0.0:8002
portal_gui_listen = 0.0.0.0:8003
portal_api_listen = 0.0.0.0:8004

admin_api_uri = https://${MANAGER_HOST}:8444
admin_gui_url = https://${MANAGER_HOST}:8445

portal              = on
portal_gui_protocol = https
portal_gui_host     = ${PORTAL_HOST}:8446
portal_api_url      = http://${PORTAL_HOST}:8447
portal_cors_origins = https://${PORTAL_HOST}:8446, https://${PORTAL_HOST}:8447

vitals = on
EOF

    for DIR in gui lib portal; do
        chown -R kong:kong /usr/local/kong/$DIR
    done
else
    # CE does not create the kong directory
    mkdir /usr/local/kong
fi

chown root:kong /usr/local/kong
chmod 2775 /usr/local/kong

# Initialize Kong
echo "Initializing Kong"
if [ "$EE_LICENSE" != "placeholder" ]; then
    ADMIN_TOKEN=$(aws_get_parameter "ee/admin/token")
    sudo -u kong KONG_PASSWORD=$ADMIN_TOKEN kong migrations bootstrap
else
    sudo -u kong kong migrations bootstrap
fi

cat <<'EOF' > /usr/local/kong/nginx.conf
worker_processes auto;
daemon off;

pid pids/nginx.pid;
error_log logs/error.log notice;

worker_rlimit_nofile 65536;

events {
    worker_connections 8192;
    multi_accept on;
}

http {
    include nginx-kong.conf;
}
EOF
chown root:kong /usr/local/kong/nginx.conf

# Log rotation
cat <<'EOF' > /etc/logrotate.d/kong
/usr/local/kong/logs/*.log {
  rotate 14
  daily
  compress
  missingok
  notifempty
  create 640 kong kong
  sharedscripts

  postrotate
    /usr/bin/sv 1 /etc/sv/kong
  endscript
}
EOF

# Allow write access for logrotate
cat <<'EOF' >> /lib/systemd/system/logrotate.service
ReadWritePaths=/usr/local/kong/logs
EOF

# Start Kong under supervision
echo "Starting Kong under supervision"
mkdir -p /etc/sv/kong /etc/sv/kong/log

cat <<'EOF' > /etc/sv/kong/run
#!/bin/sh -e
exec 2>&1

ulimit -n 65536
sudo -u kong kong prepare
exec chpst -u kong /usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf
EOF

cat <<'EOF' > /etc/sv/kong/log/run
#!/bin/sh -e

[ -d /var/log/kong ] || mkdir -p /var/log/kong
chown kong:kong /var/log/kong

exec chpst -u kong /usr/bin/svlogd -tt /var/log/kong
EOF
chmod 744 /etc/sv/kong/run /etc/sv/kong/log/run

cd /etc/service
ln -s /etc/sv/kong

# Verify Admin API is up
RUNNING=0
for I in 1 2 3 4 5 6 7 8 9; do
    curl -s -I http://localhost:8001/status | grep -q "200 OK"
    if [ $? = 0 ]; then
        RUNNING=1
        break
    fi
    sleep 1
done

if [ $RUNNING = 0 ]; then
    echo "Cannot connect to admin API, avoiding further configuration."
    exit 1
fi

# Expose & secure Kong admin API
# Configure Kong
curl http://localhost:8001/services/kong-admin-api 2>&1 | grep -q "Not found"
if [ $? = 0 ]; then
    echo "Configuring admin interface"

    ADMIN_PASS=$(aws_get_parameter "admin/password")

    curl -s -X POST http://localhost:8001/services \
      -d 'name=kong-admin-api' \
      -d 'host=127.0.0.1' \
      -d 'port=8001'

    curl -s -X POST http://localhost:8001/services/kong-admin-api/routes \
      -d "hosts[]=${ADMIN_CERT_DOMAIN}" \
      -d 'paths[]=/kong-admin-api' \
      -d 'name=kong-admin-route'

    curl -s -X POST http://localhost:8001/services/kong-admin-api/plugins \
      -d 'name=basic-auth' \
      -d 'config.hide_credentials=true'

    curl -s -X POST http://localhost:8001/routes/kong-admin-route/plugins \
      -d 'name=acl' \
      -d 'config.allow=kong-admins' \
      -d 'config.hide_groups_header=true'

    curl -s -X POST http://localhost:8001/consumers \
      -d "username=${ADMIN_USER}" \
      -d "custom_id=${ADMIN_USER}"

    curl -s -X POST http://localhost:8001/consumers/${ADMIN_USER}/basic-auth \
      -d "username=${ADMIN_USER}" \
      -d "password=$ADMIN_PASS"

    curl -s -X POST http://localhost:8001/consumers/${ADMIN_USER}/acls \
      -d "group=kong-admins"
fi

# Enable healthchecks using a kong endpoint
curl -s -I http://localhost:8000/status | grep -q "200 OK"
if [ $? != 0 ]; then
    echo "Configuring healthcheck"
    curl -s -X POST http://localhost:8001/services \
        -d name=status \
        -d host=localhost \
        -d port=8001 \
        -d path=/status
    curl -s -X POST http://localhost:8001/services/status/routes \
        -d name=status \
        -d 'methods[]=HEAD' \
        -d 'methods[]=GET' \
        -d 'paths[]=/status'
    curl -s -X POST http://localhost:8001/services/status/plugins \
        -d name=ip-restriction \
        -d "config.allow=127.0.0.1" \
        -d "config.allow=${VPC_CIDR_BLOCK}"
fi

if [ "$EE_LICENSE" != "placeholder" ]; then
    echo "Configuring enterprise edition settings"

    # Monitor role, endpoints, user, for healthcheck
    curl -s -X GET -I http://localhost:8001/rbac/roles/monitor | grep -q "200 OK"
    if [ $? != 0 ]; then
        COMMENT="Load balancer access to /status"

        curl -s -X POST http://localhost:8001/rbac/roles \
            -d name=monitor \
            -d comment="$COMMENT"
        curl -s -X POST http://localhost:8001/rbac/roles/monitor/endpoints \
            -d endpoint=/status -d actions=read \
            -d comment="$COMMENT"
        curl -s -X POST http://localhost:8001/rbac/users \
            -d name=monitor -d user_token=monitor \
            -d comment="$COMMENT"
        curl -s -X POST http://localhost:8001/rbac/users/monitor/roles \
            -d roles=monitor

        # Add authentication token for /status
        curl -s -X POST http://localhost:8001/services/status/plugins \
            -d name=request-transformer \
            -d 'config.add.headers[]=Kong-Admin-Token:monitor'
    fi

    sv stop /etc/sv/kong
    cat <<EOF >> /etc/kong/kong.conf
enforce_rbac = on
admin_gui_auth = basic-auth
admin_gui_session_conf = { "secret":"${SESSION_SECRET}", "cookie_secure":false }
EOF

    sv start /etc/sv/kong

fi
