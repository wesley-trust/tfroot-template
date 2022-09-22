package terraform.analysis

import input as tfplan

########################
# Parameters for Policy
########################

# acceptable score for automated authorization
blast_radius := 100

# weights assigned for each operation on each resource-type
weights := {
	# Resource Group
	"azurerm_resource_group": {"delete": 200, "create": 100, "modify": 1},
	# Compute
	## Virtual Machine
	"azurerm_availability_set": {"delete": 100, "create": 5, "modify": 1},
	"azurerm_linux_virtual_machine": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_windows_virtual_machine": {"delete": 100, "create": 10, "modify": 1},
	## Virtual Machine Scale Set
	"azurerm_linux_virtual_machine_scale_set": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_windows_virtual_machine_scale_set": {"delete": 100, "create": 10, "modify": 1},
	## Shutdown
	"azurerm_dev_test_global_vm_shutdown_schedule": {"delete": 100, "create": 5, "modify": 1},
	## Disks
	"azurerm_managed_disk": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_virtual_machine_data_disk_attachment": {"delete": 100, "create": 5, "modify": 1},
	# Key Vault
	"azurerm_key_vault": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_key_vault_secret": {"delete": 100, "create": 5, "modify": 1},
	"random_id": {"delete": 100, "create": 5, "modify": 1},
	## Load Balancer
	"azurerm_public_ip": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_lb": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_lb_backend_address_pool": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_lb_backend_address_pool_address": {"delete": 100, "create": 5, "modify": 1},
	"azurerm_lb_nat_rule": {"delete": 100, "create": 5, "modify": 1},
	## Network
	"azurerm_virtual_network": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_subnet": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_network_security_group": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_subnet_network_security_group_association": {"delete": 100, "create": 5, "modify": 1},
	"azurerm_route_table": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_route": {"delete": 100, "create": 5, "modify": 1},
	"azurerm_subnet_route_table_association": {"delete": 100, "create": 5, "modify": 1},
	## Network Interfaces
	"azurerm_network_interface": {"delete": 100, "create": 10, "modify": 1},
	# Network Peering
	"azurerm_virtual_network_peering": {"delete": 100, "create": 5, "modify": 1},
	# Recovery Services
	"azurerm_backup_policy_vm": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_backup_protected_vm": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_recovery_services_vault": {"delete": 100, "create": 10, "modify": 1},
	# Static Site
	"azurerm_static_site": {"delete": 100, "create": 10, "modify": 1},
	# Storage Sync
	"azurerm_role_assignment": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_storage_sync": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_storage_sync_group": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_storage_sync_cloud_endpoint": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_private_endpoint": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_storage_account": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_storage_share": {"delete": 100, "create": 10, "modify": 1},
	# Traffic Manager
	"azurerm_traffic_manager_profile": {"delete": 100, "create": 10, "modify": 1},
	"azurerm_traffic_manager_azure_endpoint": {"delete": 100, "create": 5, "modify": 1},
	# Image Gallery
	"azurerm_shared_image_gallery": {"delete": 100, "create": 10, "modify": 1},
}

# Consider exactly these resource types in calculations
resource_types := {
	"azurerm_resource_group",
	"azurerm_availability_set",
	"azurerm_linux_virtual_machine",
	"azurerm_windows_virtual_machine",
	"azurerm_linux_virtual_machine_scale_set",
	"azurerm_windows_virtual_machine_scale_set",
	"azurerm_dev_test_global_vm_shutdown_schedule",
	"azurerm_managed_disk",
	"azurerm_virtual_machine_data_disk_attachment",
	"azurerm_key_vault",
	"azurerm_key_vault_secret",
	"random_id",
	"azurerm_public_ip",
	"azurerm_lb",
	"azurerm_lb_backend_address_pool",
	"azurerm_lb_backend_address_pool_address",
	"azurerm_lb_nat_rule",
	"azurerm_virtual_network",
	"azurerm_subnet",
	"azurerm_network_security_group",
	"azurerm_subnet_network_security_group_association",
	"azurerm_route_table",
	"azurerm_route",
	"azurerm_subnet_route_table_association",
	"azurerm_network_interface",
	"azurerm_virtual_network_peering",
	"azurerm_backup_policy_vm",
	"azurerm_backup_protected_vm",
	"azurerm_recovery_services_vault",
	"azurerm_static_site",
	"azurerm_role_assignment",
	"azurerm_storage_sync",
	"azurerm_storage_sync_group",
	"azurerm_storage_sync_cloud_endpoint",
	"azurerm_private_endpoint",
	"azurerm_storage_account",
	"azurerm_storage_share",
	"azurerm_traffic_manager_azure_endpoint",
	"azurerm_traffic_manager_profile",
	"azurerm_shared_image_gallery",
}

#########
# Policy
#########

# Authorization holds if score for the plan is acceptable
default authz := false

authz {
	score < blast_radius
}

# Compute the score for a Terraform plan as the weighted sum of deletions, creations, modifications
score := s {
	all := [x |
		some resource_type
		crud := weights[resource_type]
		del := crud.delete * num_deletes[resource_type]
		new := crud.create * num_creates[resource_type]
		mod := crud.modify * num_modifies[resource_type]
		x := (del + new) + mod
	]

	s := sum(all)
}

####################
# Terraform Library
####################

# list of all resources of a given type
resources[resource_type] := all {
	some resource_type
	resource_types[resource_type]
	all := [name |
		name := tfplan.resource_changes[_]
		name.type == resource_type
	]
}

# number of creations of resources of a given type
num_creates[resource_type] := num {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	creates := [res | res := all[_]; res.change.actions[_] == "create"]
	num := count(creates)
}

# number of deletions of resources of a given type
num_deletes[resource_type] := num {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	deletions := [res | res := all[_]; res.change.actions[_] == "delete"]
	num := count(deletions)
}

# number of modifications to resources of a given type
num_modifies[resource_type] := num {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	modifies := [res | res := all[_]; res.change.actions[_] == "update"]
	num := count(modifies)
}
