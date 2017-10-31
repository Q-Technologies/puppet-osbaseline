# == Class: osbaseline::server
class osbaseline::server (
  String $definitions_path = '/etc/lobm/baselines',
  Data $configuration      = hiera_hash( 'osbaseline::server::configuration', {} ),
  Data $definitions        = lookup( 'osbaseline::server::definitions', Data, 'hash', {} ),
  String $lobm_install_from = 'package',
){

  include stdlib

  # Set up LOBM
  if $lobm_install_from == 'package' {
    # assumes the lobm package is available in a repo
    package { 'lobm':
      ensure => latest,
    }
  }
  -> file { [ '/etc/lobm', $definitions_path ]:
    ensure  => directory,
    recurse => true,
    purge   => true,
  }

  $definitions.each | $name, $data | {
    $data2 = deep_merge( { 'name' => $name }, $data )
    file { "${definitions_path}/${name}.yaml":
      ensure  => file,
      content => inline_template( '<%= @data2.to_yaml %>'),
      require => File[$definitions_path],
    }

  }

  if !empty( $configuration ){
    file { '/etc/lobm/lobm.yaml':
      ensure  => file,
      content => inline_template( '<%= @configuration.to_yaml %>'),
      require => File['/etc/lobm'],
    }
  }

}
