#
#
#
#

class openssl::install {

  package {
    'openssl':
      ensure => present,
  }

  exec {
    'update-ca-certificates':
      path        => '/usr/sbin',
      refreshonly => true
  }

}

# EOF

