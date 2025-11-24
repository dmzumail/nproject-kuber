# outputs.tf

output "k8s_cluster_id" {
  description = "Kubernetes cluster ID"
  value       = yandex_kubernetes_cluster.k8s.id
}

output "k8s_cluster_name" {
  description = "Kubernetes cluster name"
  value       = yandex_kubernetes_cluster.k8s.name
}

output "registry_id" {
  description = "Yandex Container Registry ID"
  value       = yandex_container_registry.default.id
}

output "dns_zone_id" {
  description = "ID of the public DNS zone for nproject.site"
  value       = yandex_dns_zone.public.id
}

# Раскомментируй, если нужно увидеть NS-серверы для делегирования домена
# output "dns_name_servers" {
#   description = "Name servers — set these at your domain registrar"
#   value       = yandex_dns_zone.public.name_servers
# }