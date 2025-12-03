# AWS SES Email Notification Setup

This module configures AWS Simple Email Service (SES) for sending email notifications from ArgoCD and other applications.

## Table of Contents
- [Email Authentication Explained](#email-authentication-explained)
- [How SES Works](#how-ses-works)
- [Integration Methods](#integration-methods)
- [Setup Instructions](#setup-instructions)
- [Troubleshooting](#troubleshooting)

---

## Email Authentication Explained

### Why Do We Need Email Authentication?

When you send an email, the recipient's email server needs to verify that:
1. **You are who you claim to be** (not an impersonator)
2. **The email wasn't tampered with** during transit
3. **What to do with suspicious emails**

Without these mechanisms, your emails would likely be marked as spam or rejected entirely. This is critical for automated notifications from ArgoCD, Jenkins, or any application.

### DKIM (DomainKeys Identified Mail)

**What it is**: A digital signature attached to your emails that proves they came from your domain and weren't modified.

**How it works**:
1. AWS SES adds a cryptographic signature to every email header
2. The signature is created using a private key (kept secret by AWS)
3. Your DNS publishes a public key (the 3 CNAME records we create)
4. Recipient servers use the public key to verify the signature

**Example**:
```
From: notifications@matanweisz.xyz
DKIM-Signature: v=1; a=rsa-sha256; d=matanweisz.xyz; s=key1; ...
```

**Why we need it**: Without DKIM, email providers (Gmail, Outlook) don't trust your emails and mark them as spam.

**In this project**: We enable Easy DKIM which automatically signs all outgoing emails from SES.

---

### SPF (Sender Policy Framework)

**What it is**: A DNS record that lists which mail servers are authorized to send emails on behalf of your domain.

**How it works**:
1. Your DNS publishes an SPF record (TXT record)
2. When an email arrives claiming to be from `notifications@matanweisz.xyz`
3. The recipient's server checks: "Is this email coming from an authorized server?"
4. If yes → accepted; if no → rejected/marked as spam

**Example SPF Record**:
```
v=spf1 include:amazonses.com ~all
```
This means: "Only Amazon SES is authorized to send emails from mail.matanweisz.xyz"

**Why we need it**: SPF prevents spammers from forging emails claiming to be from your domain.

**In this project**: We configure SPF for the custom MAIL FROM domain (`mail.matanweisz.xyz`).

---

### DMARC (Domain-based Message Authentication, Reporting and Conformance)

**What it is**: A policy that tells recipient servers what to do if an email fails DKIM or SPF checks.

**How it works**:
1. Your DNS publishes a DMARC policy
2. Recipient servers check if the email passes DKIM and SPF
3. If it fails, they follow your DMARC policy:
   - `p=none` → Accept it anyway (monitoring mode)
   - `p=quarantine` → Put it in spam
   - `p=reject` → Block it completely

**Example DMARC Record**:
```
v=DMARC1; p=none; rua=mailto:dmarc@matanweisz.xyz
```

**Why we need it**:
- Protects your domain from being used in phishing attacks
- Provides reports on email authentication failures
- Required by many email providers (Gmail, Yahoo require DMARC as of 2024)

**In this project**: We start with `p=none` to monitor without blocking emails. After verifying everything works, you can strengthen it to `p=quarantine` or `p=reject`.

---

### Custom MAIL FROM Domain

**What it is**: Instead of sending emails directly from `matanweisz.xyz`, we use `mail.matanweisz.xyz` as the bounce/return address.

**Why we need it**:
- **SPF Alignment**: Makes SPF checks more reliable
- **Bounce Handling**: Separates bounce/complaint emails from your main domain
- **Better Deliverability**: Email providers trust emails more when MAIL FROM and envelope sender match
- **AWS Best Practice**: SES recommends this configuration

**In this project**: All emails appear to come from `notifications@matanweisz.xyz` but the envelope sender is `mail.matanweisz.xyz`.

---

## How SES Works

### Email Delivery Flow

```
┌─────────────────┐
│   Application   │  (ArgoCD, Jenkins, etc.)
│  notifications  │
└────────┬────────┘
         │
         │ 1. Send email via SMTP or API
         ▼
┌─────────────────┐
│    AWS SES      │
│                 │
│  - Signs with   │
│    DKIM         │
│  - Adds headers │
│  - Manages      │
│    reputation   │
└────────┬────────┘
         │
         │ 2. Delivers to recipient
         ▼
┌─────────────────┐
│  Gmail/Outlook  │
│                 │
│  - Checks DKIM  │
│  - Checks SPF   │
│  - Checks DMARC │
│  - Delivers to  │
│    inbox        │
└─────────────────┘
```

### SES Components

1. **Domain Identity**: Verifies you own the domain (via DNS TXT record)
2. **Email Identity**: Verifies specific email addresses (notifications@matanweisz.xyz)
3. **SMTP Endpoint**: `email-smtp.eu-central-1.amazonaws.com:587` for sending emails
4. **Configuration Set** (optional): Track metrics, bounces, and complaints

### SES Sandbox vs Production

- **Sandbox Mode** (default): Can only send to verified email addresses (for testing)
- **Production Mode**: Can send to any email address (requires approval)

**To request production access**: AWS Console → SES → Account Dashboard → Request production access

---

## Integration Methods

### Method 1: SMTP Protocol (Recommended for most apps)

**When to use**: ArgoCD, Jenkins, Grafana, or any app that supports SMTP configuration

**Configuration**:
```yaml
smtp:
  host: email-smtp.eu-central-1.amazonaws.com
  port: 587
  from: notifications@matanweisz.xyz
  username: <SMTP_USERNAME>
  password: <SMTP_PASSWORD>
```

**How to get credentials**:
1. Go to AWS Console → SES → SMTP Settings
2. Click "Create SMTP Credentials"
3. Download the username and password

**Pros**:
- Standard protocol, works with any application
- No code changes needed
- Easy to test with tools like `swaks` or `telnet`

**Cons**:
- Requires managing SMTP credentials
- No advanced features (templates, tracking)

---

### Method 2: AWS SDK/API (For custom applications)

**When to use**: Custom Node.js, Python, Go applications where you want programmatic control

**Example (Node.js)**:
```javascript
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const sesClient = new SESClient({ region: "eu-central-1" });

async function sendNotification(to, subject, body) {
  const command = new SendEmailCommand({
    Source: "notifications@matanweisz.xyz",
    Destination: { ToAddresses: [to] },
    Message: {
      Subject: { Data: subject },
      Body: { Text: { Data: body } }
    }
  });

  await sesClient.send(command);
}
```

**Example (Python)**:
```python
import boto3

ses = boto3.client('ses', region_name='eu-central-1')

def send_notification(to, subject, body):
    ses.send_email(
        Source='notifications@matanweisz.xyz',
        Destination={'ToAddresses': [to]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body}}
        }
    )
```

**Pros**:
- Full control over email content
- Can use SES templates
- No SMTP credential management (uses IAM roles)
- Better monitoring and metrics

**Cons**:
- Requires application code changes
- Need to handle IAM permissions

---

### Method 3: IAM Role with IRSA (Kubernetes)

**When to use**: Applications running in EKS that need to send emails without hardcoded credentials

**How it works**:
1. Create IAM role with `ses:SendEmail` permission
2. Associate role with Kubernetes ServiceAccount (IRSA)
3. Application uses AWS SDK with default credentials

**Example IAM Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ],
    "Resource": "arn:aws:ses:eu-central-1:*:identity/matanweisz.xyz"
  }]
}
```

**Pros**:
- No credentials to manage
- Follows AWS security best practices
- Automatic credential rotation

**Cons**:
- Only works in AWS environments
- Requires IRSA setup

---

## Setup Instructions

### Step 1: Deploy Terraform

```bash
cd /home/matanweisz/git/matan-github/full-project/terraform/foundation

# Initialize Terraform (if not already done)
terraform init

# Review the changes
terraform plan

# Apply the configuration
terraform apply
```

**Expected outputs**:
- `route53_name_servers`: List of 4 nameservers
- `ses_notifications_email`: notifications@matanweisz.xyz
- `ses_smtp_endpoint`: email-smtp.eu-central-1.amazonaws.com

---

### Step 2: Update Domain Registrar

You need to point your domain to Route53's nameservers.

**Where you bought matanweisz.xyz** (e.g., Namecheap, GoDaddy, Cloudflare):
1. Log into your domain registrar
2. Find DNS settings or Nameservers section
3. Replace existing nameservers with the 4 values from Terraform output
4. Save changes

**Example nameservers** (yours will be different):
```
ns-123.awsdns-12.com
ns-456.awsdns-45.net
ns-789.awsdns-78.org
ns-012.awsdns-01.co.uk
```

**DNS propagation**: Can take 5 minutes to 48 hours (usually < 1 hour)

**Verify DNS propagation**:
```bash
dig NS matanweisz.xyz +short
# Should show Route53 nameservers
```

---

### Step 3: Verify SES Domain

After DNS propagates, SES will automatically verify your domain.

**Check verification status**:
```bash
aws ses get-identity-verification-attributes \
  --identities matanweisz.xyz \
  --region eu-central-1
```

**Expected output**:
```json
{
  "VerificationAttributes": {
    "matanweisz.xyz": {
      "VerificationStatus": "Success"
    }
  }
}
```

**If verification is pending**: Wait a few minutes and check again. DNS records must propagate first.

---

### Step 4: Verify Email Address

SES requires you to verify the sender email address (`notifications@matanweisz.xyz`).

**Verification is automatic when**:
- Domain is verified (matanweisz.xyz) ✓
- Email address uses verified domain ✓

**To manually verify** (if needed):
```bash
aws ses verify-email-identity \
  --email-address notifications@matanweisz.xyz \
  --region eu-central-1
```

You'll receive a verification email with a link. Click the link to verify.

**Check verification status**:
```bash
aws ses get-identity-verification-attributes \
  --identities notifications@matanweisz.xyz \
  --region eu-central-1
```

---

### Step 5: Create SMTP Credentials for ArgoCD

ArgoCD uses SMTP to send emails, so you need credentials.

**Via AWS Console**:
1. Go to: https://console.aws.amazon.com/ses/
2. Click "SMTP Settings" in the left sidebar
3. Click "Create SMTP Credentials"
4. Enter IAM User Name: `argocd-ses-smtp-user`
5. Click "Create User"
6. **Download credentials** (you can't retrieve them later!)

**Via AWS CLI** (alternative):
```bash
# Create IAM user
aws iam create-user --user-name argocd-ses-smtp-user

# Attach SES sending policy
aws iam attach-user-policy \
  --user-name argocd-ses-smtp-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonSesSendingAccess

# Create access key
aws iam create-access-key --user-name argocd-ses-smtp-user
```

**Note**: SMTP password is NOT the same as the secret access key. You need to convert it:
- Use the formula here: https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html#smtp-credentials-convert
- Or use the AWS Console method (easier)

---

### Step 6: Update ArgoCD Configuration

Edit the ArgoCD values file:

```bash
vim /home/matanweisz/git/matan-github/full-project/scripts/argocd-values.yaml
```

**Update the following sections**:

1. **Add SMTP credentials** (lines 132-133):
```yaml
stringData:
  email-username: "AKIAIOSFODNN7EXAMPLE"  # Replace with your SMTP username
  email-password: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # Replace with SMTP password
```

2. **Update notification recipient** (line 105):
```yaml
- recipients:
  - ses:your-email@example.com  # Replace with your actual email
```

**Example**:
```yaml
- recipients:
  - ses:admin@matanweisz.xyz
  - ses:devops@company.com
```

---

### Step 7: Deploy/Upgrade ArgoCD

Apply the updated configuration:

```bash
# If ArgoCD is already installed (upgrade)
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --values /home/matanweisz/git/matan-github/full-project/scripts/argocd-values.yaml

# If ArgoCD is not installed yet
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values /home/matanweisz/git/matan-github/full-project/scripts/argocd-values.yaml
```

---

### Step 8: Test Email Notifications

**Test 1: Send test email via AWS CLI**
```bash
aws ses send-email \
  --from notifications@matanweisz.xyz \
  --destination ToAddresses=your-email@example.com \
  --message "Subject={Data='Test Email'},Body={Text={Data='This is a test email from SES'}}" \
  --region eu-central-1
```

**Test 2: Trigger ArgoCD notification**

Create a test application that will fail:
```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-notification
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/invalid/repo
    targetRevision: HEAD
    path: invalid-path
  destination:
    server: https://kubernetes.default.svc
    namespace: default
EOF
```

This application will fail to sync, triggering an email notification.

**Cleanup**:
```bash
kubectl delete application test-notification -n argocd
```

---

### Step 9: Request Production Access (Optional)

By default, SES is in **Sandbox Mode**, which only allows sending to verified email addresses.

**To send to any email** (e.g., your entire team):

1. Go to: https://console.aws.amazon.com/ses/
2. Click "Account Dashboard"
3. Click "Request production access"
4. Fill out the form:
   - **Mail Type**: Transactional
   - **Website URL**: https://matanweisz.xyz
   - **Use Case Description**:
     ```
     Sending automated notifications from ArgoCD and CI/CD pipelines.
     Recipients are internal team members and on-call engineers.
     Estimated volume: < 1000 emails/day.
     ```
5. Submit request

**Approval time**: Usually 24-48 hours

**Until approved**: You must verify every recipient email address individually.

---

## Troubleshooting

### DNS Records Not Propagating

**Check DNS status**:
```bash
# Check nameservers
dig NS matanweisz.xyz +short

# Check SES verification record
dig TXT _amazonses.matanweisz.xyz +short

# Check DKIM records
dig CNAME <token>._domainkey.matanweisz.xyz +short
```

**If records don't show up**:
- Wait up to 48 hours (usually much faster)
- Verify nameservers are correctly set at registrar
- Use different DNS servers: `dig @8.8.8.8` (Google DNS)

---

### Email Not Received

**Check 1: Verify sending identity**
```bash
aws ses get-identity-verification-attributes \
  --identities notifications@matanweisz.xyz \
  --region eu-central-1
```

**Check 2: Check SES sending statistics**
```bash
aws ses get-send-statistics --region eu-central-1
```

**Check 3: Look for bounce/complaint notifications**
```bash
aws ses list-identities --region eu-central-1
```

**Check 4: Check spam folder** - Emails might be delivered but marked as spam

**Check 5: Review SES reputation**
```bash
aws ses get-account-sending-enabled --region eu-central-1
```

---

### SMTP Authentication Failed

**Error**: "535 Authentication Credentials Invalid"

**Causes**:
1. Wrong SMTP username/password
2. Using AWS secret access key instead of SMTP password
3. Wrong region

**Solution**:
- Recreate SMTP credentials via AWS Console
- Ensure you're using SMTP endpoint for eu-central-1
- Verify credentials are base64-encoded in Kubernetes secret

**Test SMTP manually**:
```bash
# Install swaks
apt-get install swaks

# Test SMTP connection
swaks --to your-email@example.com \
  --from notifications@matanweisz.xyz \
  --server email-smtp.eu-central-1.amazonaws.com:587 \
  --auth LOGIN \
  --auth-user YOUR_SMTP_USERNAME \
  --auth-password YOUR_SMTP_PASSWORD \
  --tls
```

---

### ArgoCD Notifications Not Sending

**Check 1: Verify notification controller is running**
```bash
kubectl get pods -n argocd | grep notification
```

**Check 2: Check notification controller logs**
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller
```

**Check 3: Verify secret exists**
```bash
kubectl get secret argocd-notifications-secret -n argocd
```

**Check 4: Verify configmap**
```bash
kubectl get configmap argocd-notifications-cm -n argocd -o yaml
```

**Check 5: Test notification manually**
```bash
# Create a test notification
kubectl exec -n argocd deploy/argocd-notifications-controller -- \
  argocd-notifications trigger get trigger.on-sync-failed
```

---

### Email Marked as Spam

**Reasons**:
1. DKIM not verified (wait for DNS propagation)
2. SPF record incorrect
3. DMARC policy too strict
4. SES reputation issues (if sending spam)
5. Content triggers spam filters

**Solutions**:
1. Verify all DNS records are correct and propagated
2. Check email content - avoid spam trigger words
3. Warm up sending (start with low volume)
4. Monitor bounce/complaint rates

**Check email reputation**:
- Use https://mxtoolbox.com/emailhealth/
- Check DNS: https://mxtoolbox.com/SuperTool.aspx?action=dkim
- Test email scoring: https://www.mail-tester.com/

---

### Sandbox Limitations

**Error**: "Email address is not verified"

**Cause**: SES is in Sandbox Mode, can only send to verified addresses

**Solutions**:
1. **Verify recipient email**:
   ```bash
   aws ses verify-email-identity \
     --email-address recipient@example.com \
     --region eu-central-1
   ```

2. **Request production access** (see Step 9)

---

## Security Best Practices

1. **SMTP Credentials**:
   - Store in Kubernetes secrets (never in git)
   - Rotate credentials every 90 days
   - Use unique credentials per application

2. **IAM Permissions**:
   - Use least-privilege IAM policies
   - Restrict to specific SES identities
   - Use IRSA instead of long-lived credentials

3. **Monitoring**:
   - Set up CloudWatch alarms for bounce rate
   - Monitor complaint rate (should be < 0.1%)
   - Track sending quotas

4. **DMARC Policy**:
   - Start with `p=none` for monitoring
   - Move to `p=quarantine` after 2-4 weeks
   - Move to `p=reject` for maximum protection

---

## Cost Considerations

**SES Pricing (as of 2024)**:
- First 62,000 emails/month: **FREE** (when sending from EC2/EKS)
- After that: $0.10 per 1,000 emails
- Attachments: $0.12 per GB

**Route53 Pricing**:
- Hosted zone: $0.50/month
- Queries: $0.40 per million queries (first 1 billion)

**Total cost for this setup**: ~$0.50-1.00/month (assuming < 62k emails)

---

## Additional Resources

- [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/latest/dg/)
- [ArgoCD Notifications](https://argocd-notifications.readthedocs.io/en/stable/)
- [SPF Record Syntax](http://www.open-spf.org/SPF_Record_Syntax/)
- [DMARC.org](https://dmarc.org/)
- [Email Authentication Best Practices](https://www.m3aawg.org/sites/default/files/m3aawg-email-authentication-recommended-best-practices-09-2020.pdf)
