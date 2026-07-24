output "stack_version" {
  value = local.stack_version

  precondition {
    condition     = length(local.conflicting_cp_display_names) == 0
    error_message = "Planned control plane node display names already exist in the compartment: ${join(", ", tolist(local.conflicting_cp_display_names))}."
  }

  precondition {
    condition     = length(local.conflicting_compute_display_names) == 0
    error_message = "Planned compute node display names already exist in the compartment: ${join(", ", tolist(local.conflicting_compute_display_names))}."
  }
}
