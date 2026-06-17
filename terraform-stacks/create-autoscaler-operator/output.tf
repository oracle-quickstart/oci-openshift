output "autoscaling_manifest" {
  description = "Autoscaling operator manifest bundle to apply in cluster."
  value       = module.autoscaling_manifest.autoscaling_manifest
}
