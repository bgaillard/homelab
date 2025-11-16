locals {
  etcds ={
    etcd_1 = {
      name = "etcd-1"
      ipv4_address = "10.0.0.11"
    },
    etcd_2 = {
      name = "etcd-2"
      ipv4_address = "10.0.0.12"
    },
    etcd_3 = {
      name = "etcd-3"
      ipv4_address = "10.0.0.13"
    }
  }
}
