# Phase 9 Complete: Monitoring & Logging ✅

## Status: COMPLETE

Comprehensive monitoring and logging configured for production operations.

---

## Deliverables

### 1. CloudWatch Logging ✅
- Log groups for all Lambda functions (30-day retention)
- API Gateway access logs
- Structured JSON logging in Lambda
- Correlation IDs in logs

### 2. CloudWatch Metrics ✅
- API Gateway: Request count, latency, 4XX/5XX errors
- Lambda: Invocations, duration, errors, throttles
- DynamoDB: Read/write capacity, throttles
- EventBridge: Invocations, failed invocations

### 3. CloudWatch Alarms ✅
- API Gateway 5XX errors (threshold: 10)
- Lambda errors per function (threshold: 5)
- Automatic alarm creation for all Lambda functions

### 4. X-Ray Tracing ✅
- Enabled on all Lambda functions
- Enabled on API Gateway
- End-to-end request tracing
- Service map visualization

---

## Files Created

1. `terraform/modules/cloudwatch-alarms/main.tf` - Alarm definitions
2. `terraform/modules/cloudwatch-alarms/variables.tf` - Module variables
3. `terraform/modules/cloudwatch-alarms/outputs.tf` - Module outputs
4. `terraform/main.tf` - Added alarms module

---

## Monitoring Stack

### CloudWatch Logs
```
/aws/lambda/task-manager-sandbox-pre-signup
/aws/lambda/task-manager-sandbox-task-api
/aws/lambda/task-manager-sandbox-notification-handler
/aws/apigateway/task-manager-sandbox-api
```

**Retention:** 30 days  
**Format:** JSON structured logs

### CloudWatch Metrics

**API Gateway:**
- Count (total requests)
- 4XXError, 5XXError
- Latency (p50, p90, p99)
- IntegrationLatency

**Lambda:**
- Invocations
- Errors
- Duration
- Throttles
- ConcurrentExecutions

**DynamoDB:**
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- UserErrors (throttles)

**EventBridge:**
- Invocations
- FailedInvocations
- TriggeredRules

### CloudWatch Alarms

**API 5XX Errors:**
- Threshold: 10 errors in 5 minutes
- Action: Alarm state (SNS topic can be added)

**Lambda Errors:**
- Threshold: 5 errors in 5 minutes per function
- Functions: pre-signup, task-api, notification-handler

---

## View Logs

### Lambda Logs
```bash
# Task API
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow

# Notification Handler
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow

# Pre Sign-Up
aws logs tail /aws/lambda/task-manager-sandbox-pre-signup --follow
```

### API Gateway Logs
```bash
aws logs tail /aws/apigateway/task-manager-sandbox-api --follow
```

### Filter Logs
```bash
# Errors only
aws logs filter-log-events \
  --log-group-name /aws/lambda/task-manager-sandbox-task-api \
  --filter-pattern "ERROR"

# Specific request ID
aws logs filter-log-events \
  --log-group-name /aws/lambda/task-manager-sandbox-task-api \
  --filter-pattern "request-id-123"
```

---

## View Metrics

### API Gateway Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=task-manager-sandbox-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Lambda Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=task-manager-sandbox-task-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## X-Ray Tracing

### View Traces
```bash
# Get trace summaries
aws xray get-trace-summaries \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s)

# Get specific trace
aws xray batch-get-traces --trace-ids <trace-id>
```

### Service Map
AWS Console → X-Ray → Service map

Shows:
- API Gateway → Lambda → DynamoDB
- Lambda → EventBridge
- Lambda → SES

---

## Alarms

### List Alarms
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix task-manager-sandbox
```

### Alarm States
- OK: Metric within threshold
- ALARM: Metric exceeded threshold
- INSUFFICIENT_DATA: Not enough data

### Add SNS Notifications (Optional)
```bash
# Create SNS topic
aws sns create-topic --name task-manager-alarms

# Subscribe email
aws sns subscribe \
  --topic-arn <topic-arn> \
  --protocol email \
  --notification-endpoint admin@amalitech.com

# Update alarm
aws cloudwatch put-metric-alarm \
  --alarm-name task-manager-sandbox-api-5xx-errors \
  --alarm-actions <topic-arn>
```

---

## Dashboards (Optional)

### Create Dashboard
```bash
aws cloudwatch put-dashboard \
  --dashboard-name task-manager \
  --dashboard-body file://dashboard.json
```

### Dashboard Widgets
- API request count (line chart)
- API error rate (line chart)
- Lambda invocations (line chart)
- Lambda errors (line chart)
- Lambda duration (line chart)
- DynamoDB capacity (line chart)

---

## Cost

**CloudWatch Logs:** ~$0.50/GB ingested + $0.03/GB stored  
**CloudWatch Metrics:** First 10 custom metrics free  
**CloudWatch Alarms:** First 10 alarms free  
**X-Ray:** First 100K traces/month free  

**Estimated:** ~$2-5/month for typical usage

---

## Best Practices Implemented

✅ Structured logging (JSON)  
✅ Log retention policies (30 days)  
✅ Correlation IDs for tracing  
✅ X-Ray tracing enabled  
✅ CloudWatch alarms for critical metrics  
✅ Metrics for all services  
✅ Access logs for API Gateway  

---

## Progress: 80% Complete

✅ Phases: 1, 2, 3, 4, 5, 6, 7, 8, 9  
⏳ Next: Phase 10 (Testing & Validation)

---

**Monitoring Status:** Production-ready observability stack
