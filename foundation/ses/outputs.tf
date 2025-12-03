output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route53 name servers - update these in your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "ses_domain_identity" {
  description = "SES domain identity"
  value       = aws_ses_domain_identity.main.domain
}

output "ses_domain_identity_arn" {
  description = "SES domain identity ARN"
  value       = aws_ses_domain_identity.main.arn
}

output "mail_from_domain" {
  description = "Mail FROM domain"
  value       = aws_ses_domain_mail_from.main.mail_from_domain
}

output "notifications_email" {
  description = "Verified email address for sending notifications"
  value       = aws_ses_email_identity.notifications.email
}

output "smtp_endpoint" {
  description = "SES SMTP endpoint for the region"
  value       = "email-smtp.${var.aws_region}.amazonaws.com"
}
