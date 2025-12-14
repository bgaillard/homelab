locals {
  control_planes = {
    control_plane_1 = {
      name         = "control-plane-1"
      ipv4_address = "10.0.0.21"
    }
    control_plane_2 = {
      name         = "control-plane-2"
      ipv4_address = "10.0.0.22"
    }
    control_plane_3 = {
      name         = "control-plane-3"
      ipv4_address = "10.0.0.23"
    }
  }

  etcds = {
    etcd_1 = {
      name         = "etcd-1"
      ipv4_address = "10.0.0.11"
    },
    etcd_2 = {
      name         = "etcd-2"
      ipv4_address = "10.0.0.12"
    },
    etcd_3 = {
      name         = "etcd-3"
      ipv4_address = "10.0.0.13"
    }
  }

  load_balancers = {
    load_balancer_1 = {
      name         = "load-balancer-1"
      ipv4_address = "10.0.0.31"
    }
    load_balancer_2 = {
      name         = "load-balancer-2"
      ipv4_address = "10.0.0.32"
    }
  }

  workers = {
    worker_1 = {
      name         = "worker-1"
      ipv4_address = "10.0.0.61"
    }
    worker_2 = {
      name         = "worker-2"
      ipv4_address = "10.0.0.62"
    }
    worker_3 = {
      name         = "worker-3"
      ipv4_address = "10.0.0.63"
    }
  }

}
