provider "incus" {
  accept_remote_certificate = true
  default_remote            = "homelab"

  # The remote is configured in the  '~/.config/incus/config.yml' file of the Incus client.
  #
  # Example of content to place in the Incus client 'config.yml' file.
  #
  #   remotes:
  #     ...
  #     homelab:
  #       addr: https://homelab:8443
  #       auth_type: tls
  #       project: default
  #       protocol: incus
  #       public: false
  #     ...
  #
  # After add the 'incus remote list' command should show the remote on the Incus client.
  #
  # Finaly add the '~/.config/incus/client.crt' Incus client certificate to the Incus server trusted certificates.
  #  1. On client side 'scp ~/.config/incus/client.crt baptiste@homelab:/tmp/client.crt'
  #  2. On server side 'incus config trust add-certificate /tmp/client.crt'
  #
  # @see https://linuxcontainers.org/incus/docs/main/remotes/#configure-a-global-remote
  # @see https://linuxcontainers.org/incus/docs/main/authentication/#trusted-tls-clients
  remote {
    name = "homelab"
  }
}
