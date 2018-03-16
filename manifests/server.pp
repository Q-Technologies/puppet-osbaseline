# == Class: osbaseline::server
class osbaseline::server (
  String $definitions_path = '/etc/lobm/baselines',
  Data $configuration      = lookup( 'osbaseline::server::configuration', Data, 'deep', {} ),
  Data $definitions        = lookup( 'osbaseline::server::definitions', Data, 'deep', {} ),
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
