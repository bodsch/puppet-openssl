#
#
#
#

class openssl::config {

  file {
    "/etc/ssl/${domain}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755'
  }

}

# EOF

