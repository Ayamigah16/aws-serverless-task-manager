resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.collection_name}-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.collection_name}"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.collection_name}-network"
  type = "network"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.collection_name}"]
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_access_policy" "data" {
  name = "${var.collection_name}-access"
  type = "data"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.collection_name}"]
      Permission = [
        "aoss:CreateCollectionItems",
        "aoss:UpdateCollectionItems",
        "aoss:DescribeCollectionItems"
      ]
      }, {
      ResourceType = "index"
      Resource     = ["index/${var.collection_name}/*"]
      Permission = [
        "aoss:CreateIndex",
        "aoss:UpdateIndex",
        "aoss:DescribeIndex",
        "aoss:ReadDocument",
        "aoss:WriteDocument"
      ]
    }]
    Principal = [
      var.lambda_role_arn,
      var.appsync_role_arn
    ]
  }])
}

resource "aws_opensearchserverless_collection" "main" {
  name = var.collection_name
  type = "SEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data
  ]

  tags = {
    Name        = var.collection_name
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Log Group for OpenSearch
resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${var.collection_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.collection_name}-logs"
    Project     = var.project_name
    Environment = var.environment
  }
}
