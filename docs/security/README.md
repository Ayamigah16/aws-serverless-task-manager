# Security Documentation

Comprehensive security guide for the AWS Serverless Task Manager.

## 📋 Table of Contents

- [Security Overview](#security-overview)
- [Authentication & Authorization](#authentication--authorization)
- [Data Security](#data-security)
- [Network Security](#network-security)
- [Security Best Practices](#security-best-practices)
- [Compliance & Auditing](#compliance--auditing)

## Security Overview

This project implements multiple layers of security:

1. **Authentication**: AWS Cognito with MFA support
2. **Authorization**: Role-based access control (RBAC)
3. **Data Encryption**: At rest and in transit
4. **Network Security**: API Gateway, VPC integration
5. **Secrets Management**: AWS Secrets Manager
6. **Monitoring**: CloudWatch, AWS CloudTrail

### Security Architecture

See [Security Architecture](../architecture/05-security-architecture.md) for detailed architecture diagrams.

## Authentication & Authorization

### AWS Cognito

**User Pools**:
- Email-based authentication
- Password policies enforced
- MFA available
- Account recovery via email

**User Groups**:
- `Admins` - Full access
- `ProjectManagers` - Project and team management
- `Members` - View and update assigned tasks

### JWT Token Validation

```javascript
// Lambda authorizer
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`
});

async function verifyToken(token) {
  const decoded = jwt.decode(token, { complete: true });
  const key = await client.getSigningKey(decoded.header.kid);
  const signingKey = key.getPublicKey();
  
  return jwt.verify(token, signingKey, {
    algorithms: ['RS256'],
    issuer: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`
  });
}
```

### Role-Based Access Control

```javascript
// Check user permissions
function hasPermission(user, resource, action) {
  const roles = user['cognito:groups'] || [];
  
  // Admins have all permissions
  if (roles.includes('Admins')) return true;
  
  // Project managers can manage their projects
  if (roles.includes('ProjectManagers')) {
    if (action.startsWith('project:')) return true;
  }
  
  // Members can view and update their tasks
  if (roles.includes('Members')) {
    if (action === 'task:read' || action === 'task:update') {
      return resource.assignedTo === user.sub;
    }
  }
  
  return false;
}
```

## Data Security

### Encryption at Rest

**DynamoDB**:
- AWS-managed encryption (KMS)
- Per-table encryption keys
- Automated key rotation

**S3**:
- Server-side encryption (SSE-S3)
- Bucket policies enforcing encryption
- Versioning enabled

**Secrets**:
- AWS Secrets Manager with KMS
- Automatic rotation
- IAM-based access control

### Encryption in Transit

- **API Gateway**: HTTPS only
- **CloudFront**: TLS 1.2+ required
- **Lambda**: VPC with private subnets (optional)
- **DynamoDB**: TLS connections

### Data Classification

| Level | Description | Examples | Protection |
|-------|-------------|----------|------------|
| Public | No sensitivity | Feature flags | None required |
| Internal | Company use | Project names | Authentication |
| Confidential | Restricted | User emails | Encryption + RBAC |
| Highly Confidential | Critical data | Passwords, tokens | KMS encryption + audit |

### Sensitive Data Handling

```javascript
// Redacting sensitive data in logs
function sanitizeForLogging(data) {
  const sanitized = { ...data };
  const sensitiveFields = ['password', 'token', 'secret', 'email'];
  
  sensitiveFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  });
  
  return sanitized;
}

// Usage
console.log('User data:', sanitizeForLogging(userData));
```

## Network Security

### API Gateway Security

- **API Keys**: For rate limiting
- **Usage Plans**: Throttling and quotas
- **CORS**: Restrictive origins
- **WAF**: Web Application Firewall (optional)

```javascript
// API Gateway CORS configuration
{
  "AllowOrigins": ["https://app.example.com"],
  "AllowMethods": ["GET", "POST", "PUT", "DELETE"],
  "AllowHeaders": ["Authorization", "Content-Type"],
  "AllowCredentials": true,
  "MaxAge": 300
}
```

### VPC Configuration (Optional)

```hcl
# terraform/modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### Security Groups

```hcl
resource "aws_security_group" "lambda" {
  name        = "task-manager-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to AWS services"
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Database access"
  }
}
```

## Security Best Practices

See [Security Review](SECURITY_REVIEW.md) for comprehensive review results.

### ✅ Do's

- ✅ Use IAM roles with least privilege
- ✅ Enable MFA for admin users
- ✅ Rotate credentials regularly
- ✅ Use AWS Secrets Manager for secrets
- ✅ Enable CloudTrail logging
- ✅ Use VPC for Lambda functions (production)
- ✅ Implement rate limiting
- ✅ Validate all inputs
- ✅ Use prepared statements for queries
- ✅ Keep dependencies updated
- ✅ Scan for vulnerabilities regularly

### ❌ Don'ts

- ❌ Hardcode credentials
- ❌ Use overly permissive IAM policies
- ❌ Disable encryption
- ❌ Expose sensitive data in logs
- ❌ Use deprecated AWS services
- ❌ Skip input validation
- ❌ Store secrets in environment variables
- ❌ Use default security groups
- ❌ Ignore security updates
- ❌ Deploy without testing

### IAM Least Privilege

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:eu-west-1:*:table/task-manager-${environment}-main",
        "arn:aws:dynamodb:eu-west-1:*:table/task-manager-${environment}-main/index/*"
      ],
      "Condition": {
        "ForAllValues:StringEquals": {
          "dynamodb:LeadingKeys": ["${cognito:sub}"]
        }
      }
    }
  ]
}
```

### Input Validation

```javascript
const Joi = require('joi');

const taskSchema = Joi.object({
  title: Joi.string().min(1).max(200).required(),
  description: Joi.string().max(2000),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'DONE'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH'),
  assignedTo: Joi.string().uuid(),
  dueDate: Joi.date().iso()
});

function validateTask(task) {
  const { error, value } = taskSchema.validate(task, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    throw new ValidationError(error.details);
  }
  
  return value;
}
```

### SQL Injection Prevention

```javascript
// ✅ Good: Parameterized queries
const params = {
  TableName: DYNAMODB_TABLE,
  Key: { PK: userId, SK: taskId },
  UpdateExpression: 'SET #title = :title, #status = :status',
  ExpressionAttributeNames: {
    '#title': 'title',
    '#status': 'status'
  },
  ExpressionAttributeValues: {
    ':title': sanitizedTitle,
    ':status': sanitizedStatus
  }
};

// ❌ Bad: String concatenation
const query = `SELECT * FROM tasks WHERE id = '${taskId}'`;
```

## Compliance & Auditing

### CloudTrail Logging

```hcl
resource "aws_cloudtrail" "main" {
  name                          = "task-manager-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["arn:aws:dynamodb:*:*:table/task-manager-*"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function:task-manager-*"]
    }
  }
}
```

### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "UnauthorizedAPICalls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert on unauthorized API calls"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Security Scanning

#### Automated Scans (CI/CD)

```yaml
# .github/workflows/security-scan.yml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Run secret scanning
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
```

#### Manual Security Testing

```bash
# npm audit
cd frontend && npm audit
cd lambda/task-api && npm audit

# OWASP dependency check
./scripts/security-tests.sh

# Terraform security scan
cd terraform
tfsec .
```

### Incident Response

**Security Incident Playbook**:

1. **Detection**: CloudWatch Alarms, GuardDuty
2. **Containment**: Revoke compromised credentials, block IPs
3. **Investigation**: Review CloudTrail logs, analyze access patterns
4. **Remediation**: Patch vulnerabilities, rotate secrets
5. **Recovery**: Restore from backups if needed
6. **Post-mortem**: Document incident, update procedures

### Compliance Requirements

| Standard | Requirements | Implementation |
|----------|--------------|----------------|
| SOC 2 | Access controls, encryption, logging | IAM, KMS, CloudTrail |
| GDPR | Data privacy, right to deletion | Data anonymization, deletion APIs |
| HIPAA | PHI encryption, audit trails | Encryption at rest/transit, CloudTrail |
| PCI DSS | Network segmentation, encryption | VPC, TLS, tokenization |

## Security Monitoring

### Dashboard

```bash
# View security events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
  --max-results 50

# Check for unauthorized access
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 4XXError \
  --start-time 2026-02-12T00:00:00Z \
  --end-time 2026-02-12T23:59:59Z \
  --period 300 \
  --statistics Sum
```

### Regular Security Reviews

- **Weekly**: Review CloudWatch alarms and security logs
- **Monthly**: Update dependencies, rotate non-prod credentials
- **Quarterly**: Security audit, penetration testing
- **Annually**: Compliance review, security training

## Additional Resources

- [Security Review](SECURITY_REVIEW.md) - Complete security audit
- [Security Architecture](../architecture/05-security-architecture.md) - Architecture diagrams
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Last Updated**: February 2026  
**Security Contact**: security@example.com
