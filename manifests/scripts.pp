# == Class: osbaseline::scripts
class osbaseline::scripts (
  Boolean $install = false,

  # Get the script paths for Perl scripts
  String $selection_script_path,
  String $selection_config_path,
  Data $selection_config = lookup('osbaseline::scripts::selection_config', Data, 'deep', {}),

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

    # Config file for Baseline Selection script
    file { 'baseline_selection_config':
      ensure  => file,
      path    => $selection_config_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => inline_template('<%= @selection_config.to_yaml %>'),
    }
  }


}
