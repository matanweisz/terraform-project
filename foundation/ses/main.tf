# Route53 Hosted Zone for domain
resource "aws_route53_zone" "main" {
  name    = var.domain
  comment = "Managed by Terraform for ${var.domain}"
}

# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.domain
}

# SES Domain Verification Record
resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# Enable DKIM for domain
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# DKIM CNAME Records
resource "aws_route53_record" "dkim" {
  for_each = toset(aws_ses_domain_dkim.main.dkim_tokens)

  zone_id = aws_route53_zone.main.zone_id
  name    = "${each.value}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${each.value}.dkim.amazonses.com"]
}

# Custom MAIL FROM domain configuration
resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${var.domain}"
}

# MX record for MAIL FROM domain
resource "aws_route53_record" "mail_from_mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mail.${var.domain}"
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]
}

# SPF record for MAIL FROM domain
resource "aws_route53_record" "mail_from_spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mail.${var.domain}"
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC policy record
resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=none; rua=mailto:dmarc@${var.domain}"]
}

# Create verified email identity for sending (e.g., notifications@matanweisz.xyz)
resource "aws_ses_email_identity" "notifications" {
  email = "notifications@${var.domain}"
}
