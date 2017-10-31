# Maintaining SOE Groups in Puppet

## Script
    puppet_baseline_selection.pl

This script uses the Puppet Node Classifier API to add remove batches of nodes.  This version is tailored for maintaining SOE 
groups (groups that control which version of the SOE should be applied to a node).

### Options
* -a (action)
  * init_soe - for new Puppet Masters, set up the default group
  * empty_group - remove all nodes from the group
  * add_to_group - add more nodes to the group
  * list_group - list the nodes in a group
  * list_groups - list the groups matching the SOE pattern
  * add_group - add a new group and optionally add some nodes at the same time (-f will allow you to redefine an existing node)
  * purge_old_nodes - remove all the nodes in all the SOE groups that are not in the PuppetDB
  * remove_from_group - remove nodes from a group
  * remove_group - remove the group entirely
* -g (group name, can just be date)
* -f (force - some operations may need forcing)
* -v (some progress messages)
* -d (extra messages)

### Examples
#### Add a  new SOE group
    sudo /usr/local/sbin/puppet_baseline_selection.pl -a add_group -g 2016-09-01 node1.fqdn node2.fqdn node3.fqdn
#### Add additional nodes to a SOE group
    sudo /usr/local/sbin/puppet_baseline_selection.pl -a add_to_group -g 2016-09-01 node1.fqdn node2.fqdn node3.fqdn
#### Remove nodes from a SOE group
    sudo /usr/local/sbin/puppet_baseline_selection.pl -a remove_from_group -g 2016-09-01 node1.fqdn node2.fqdn node3.fqdn
