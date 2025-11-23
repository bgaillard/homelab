resource "incus_storage_pool" "load_balancer" {
  project = incus_project.this.name
  name    = "load-balancer"
  driver  = "dir"
}

# @see https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#keepalived-and-haproxy
# @see https://itnext.io/create-a-highly-available-kubernetes-cluster-using-keepalived-and-haproxy-37769d0a65ba
resource "incus_instance" "load_balancer" {
  for_each = local.load_balancers
  # for_each = {}

  project     = incus_project.this.name
  name        = each.value.name
  description = "Load balancer node ${each.value.name}"

  # Important, use '/cloud' images to be able to use cloud-init.
  #
  # @see https://images.linuxcontainers.org/
  image = "images:debian/trixie/cloud"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.this.name
      "ipv4.address" = each.value.ipv4_address
    }
  }

  # @see https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "limits.memory" = "256MB"
    "cloud-init.user-data" = join(
      "\n",
      [
        "#cloud-config", 
        yamlencode(
          {
            package_update = true
            package_upgrade = true
            packages = [
              "keepalived"
            ]
            # FIXME: Keepalived executed as root
            runcmd = [
              "apt-get update",
              "apt-get install -y keepalived haproxy",

              "chmod 0:0 /etc/keepalived/check_api_server.sh",

              "systemctl enable haproxy",
              "systemctl start haproxy",

              "systemctl enable keepalived",
              "systemctl start keepalived"
            ]
            write_files = [
              {
                path = "/etc/keepalived/keepalived.conf",
                content = <<-EOF
global_defs {
  router_id LVS_DEVEL
}

vrrp_script check_api_server {
  script "/etc/keepalived/check_api_server.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance vip {
  state ${each.key == "load_balancer_1" ? "MASTER" : "BACKUP"}
  interface eth0
  virtual_router_id 10
  priority 100
  authentication {
    auth_type PASS
    auth_pass 1234
  }
  virtual_ipaddress {
    ${local.load_balancer_vip}
  }
  track_script {
    check_api_server
  }
}
EOF
              },

              {
                path = "/etc/keepalived/check_api_server.sh",
                content = <<-EOF
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl -sfk --max-time 2 https://localhost:6443/healthz -o /dev/null || errorExit "Error GET https://localhost:6443/healthz"
EOF
              },

              # FIXME: HaProxy is configured with the root user here, we should use haproxy/haproxy
              {
                path = "/etc/haproxy/haproxy.cfg",
                content = <<-EOF
global
        log /dev/log    local0
        log /dev/log    local1 notice
        stats timeout 30s
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend kube-apiserver
  bind *:6443
  mode tcp
  option tcplog
  default_backend kube-apiserver

backend kube-apiserver
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server control-plane-1 ${local.control_planes.control_plane_1.ipv4_address}:6443 check
    server control-plane-2 ${local.control_planes.control_plane_2.ipv4_address}:6443 check
    server control-plane-3 ${local.control_planes.control_plane_2.ipv4_address}:6443 check
EOF
              }
            ]
          }
        )
      ]
   )
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      path = "/"
      pool = incus_storage_pool.load_balancer.name
      size = "1GB"
    }
  }
}

