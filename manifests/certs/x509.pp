#
#
#
#

define openssl::certs::x509(
  $country,
  $organization,
  $commonname,
  $ensure     = present,
  $state      = undef,
  $locality   = undef,
  $unit       = undef,
  $altnames   = [],
  $email      = undef,
  $days       = 365,
  $base_dir   = '/etc/ssl/certs',
  $owner      = 'root',
  $group      = 'root',
  $password   = undef,
  $force      = true,
) {

  validate_string($name)
  validate_string($country)
  validate_string($organization)
  validate_string($commonname)
  validate_string($ensure)
  validate_string($state)
  validate_string($locality)
  validate_string($unit)
  validate_array($altnames)
  validate_string($email)
  validate_string($days)
  validate_re($days, '^\d+$')
  validate_string($base_dir)
  validate_absolute_path($base_dir)
  validate_string($owner)
  validate_string($group)
  validate_string($password)
  validate_bool($force)
  validate_re($ensure, '^(present|absent)$',
    "\$ensure must be either 'present' or 'absent', got '${ensure}'")


  file {
    "${base_dir}/${name}.cnf":
      ensure  => $ensure,
      owner   => $owner,
      group   => $group,
      content => template( 'openssl/cert.cnf.erb' ),
      require => File["${base_dir}"]
  }

  file {
    "${base_dir}/${name}.pass":
      ensure  => present,
      content => "${password}",
      require => File["${base_dir}"]
  }

  if $force == true {

    exec {
      "remove  - ${name}":
        path    => '/bin',
        command => "rm -f ${base_dir}/${name}*",
        before  => [
          Exec["create openssl key - ${name}"],
          Exec["remove passphrase - ${name}"],
          Exec["create openssl csr - ${name}"],
          Exec["selfsign our key - ${name}"],
          Exec["build pem - ${name}"]
        ]
    }
  }

  exec {
    "create openssl key - ${name}":
      path    => '/usr/bin',
      command => "openssl genrsa -aes256 -passout file:${base_dir}/${name}.pass -out ${base_dir}/${name}.key 4096",
      onlyif  => "test ! -f ${base_dir}/${name}.key",
      require => File["${base_dir}/${name}.pass"]
  }

  exec {
    "remove passphrase - ${name}":
      path    => '/usr/bin',
      command => "openssl rsa -passin file:${base_dir}/${name}.pass -in ${base_dir}/${name}.key -out ${base_dir}/${name}.key.unsecure",
      onlyif  => "test ! -f ${base_dir}/${name}.key.unsecure",
      require => Exec["create openssl key - ${name}"]
  }

  exec {
    "create openssl csr - ${name}":
      path    => '/usr/bin',
      command => "openssl req -new -passin file:${base_dir}/${name}.pass -key ${base_dir}/${name}.key -days ${days} -nodes -out ${base_dir}/${name}.csr -config ${base_dir}/${name}.cnf",
      onlyif  => "test ! -f ${base_dir}/${name}.csr",
      require => Exec["remove passphrase - ${name}"]
  }

  exec {
    "selfsign our key - ${name}":
      path    => '/usr/bin',
      command => "openssl x509 -req -passin file:${base_dir}/${name}.pass -days ${days} -in ${base_dir}/${name}.csr -signkey ${base_dir}/${name}.key -out ${base_dir}/${name}.crt",
      onlyif  => "test ! -f ${base_dir}/${name}.crt",
      require => Exec["create openssl csr - ${name}"]
  }

  exec {
    "build pem - ${name}":
      path    => [
        '/bin',
        '/usr/bin'
      ],
      command => "cat ${base_dir}/${name}.key.unsecure ${base_dir}/${name}.crt > ${base_dir}/${name}.pem ;  openssl gendh >> ${base_dir}/${name}.pem",
      onlyif  => "test ! -f ${base_dir}/${name}.pem",
      require => Exec["selfsign our key - ${name}"]
  }

}

# EOF

# display the content :
#  openssl req -in /etc/ssl/hagema.lan/server.csr -noout -text
#  openssl x509 -in /etc/ssl/hagema.lan/server.pem -text
#
# fingerprint
#  openssl x509 -fingerprint -noout -in /etc/ssl/hagema.lan/server.pem
#
# verify that your private key, CSR, and signed cert match by comparing:
#  openssl rsa -noout -modulus -in /etc/ssl/hagema.lan/server.pem | openssl md5
#  openssl req -noout -modulus -in /etc/ssl/hagema.lan/server.csr | openssl md5
#  openssl x509 -noout -modulus -in /etc/ssl/hagema.lan/server.pem | openssl md
#
#
#  openssl s_client -host 127.0.0.1 -port 25 -starttls smtp
#  openssl s_client -connect server:port -crlf



