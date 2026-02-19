output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}

output "s3_bucket_name" {
  value = module.frontend_s3.bucket_name
}

output "amp_workspace_id" {
  value = module.iam.amp_workspace_id
}

output "sns_topic_arn" {
  value = module.iam.sns_topic_arn
}
