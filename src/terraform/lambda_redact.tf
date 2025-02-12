data aws_iam_policy_document "redact_pii_data" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = [
      "comprehend:DetectPiiEntities",
      "comprehend:ContainsPiiEntities",
      "comprehendmedical:*"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
  }

}

module "redact_pii_data" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.1"

  function_name = "${var.project_prefix}-redact"
  description   = "Generate S3 pre-signed URL to upload file"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "../lambda/functions/redact/src"

  store_on_s3 = true
  s3_bucket   = module.s3_artifact_repository.s3_bucket_id

  layers = [
    module.lambda_layer.lambda_layer_arn,
  ]
  timeout = 60
  architectures = ["arm64"]
  attach_cloudwatch_logs_policy = true
  attach_tracing_policy         = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.redact_pii_data.json
  tracing_mode                  = "Active"

  environment_variables = {
    redact_keys = "name,surname,telephone,email,address,ssn,birthdate"
    pii_evalutation = "physician_annotation"
  }
}


