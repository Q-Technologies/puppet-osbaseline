# == Class: osbaseline::scripts
class osbaseline::scripts (

  # Get the script paths for Perl scripts
  String $selection_script_path,
  String $selection_config_path,
  Data $selection_config_default,
  Data $selection_config = lookup('osbaseline::scripts::selection_config', Data, 'deep', {}),

  # Whether to install the scripts or not
  Boolean $install = false,

){

  if $install {
    # Baseline Selection script
    file { 'baseline_selection':
      ensure  => file,
      path    => $selection_script_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => epp('osbaseline/baseline_selection.pl.epp', { selection_config_path => $selection_config_path })
    }

    $selection_config_merged = $selection_config_default + $selection_config

    # Config file for Baseline Selection script
    file { 'baseline_selection_config':
      ensure  => file,
      path    => $selection_config_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => inline_template('<%= @selection_config_merged.to_yaml %>'),
    }
  }


}
