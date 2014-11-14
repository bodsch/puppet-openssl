#
#
#
#

class openssl {

  class { 'openssl::install': } ->
  class { 'openssl::config': }

}

# EOF

