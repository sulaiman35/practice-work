output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "alb_dns_name" {
  value = aws_alb.ecs_alb.dns_name
}
