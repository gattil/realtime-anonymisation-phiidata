data aws_iam_policy_document "physician_notes" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
  }

}

module "physician_notes" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.1"

  function_name = "${var.project_prefix}-physician-notes"
  description   = "Generate Physician Notes"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "../lambda/functions/physician_notes/src"

  store_on_s3 = true
  s3_bucket   = module.s3_artifact_repository.s3_bucket_id

  layers = [
    module.lambda_layer.lambda_layer_arn,
  ]
  timeout                       = 60
  architectures                 = ["arm64"]
  attach_cloudwatch_logs_policy = true
  attach_tracing_policy         = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.physician_notes.json
  tracing_mode                  = "Active"

  environment_variables = {
    delivery_stream = aws_kinesis_firehose_delivery_stream.delivery_stream_notes.name
  }

}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_physician" {
  count         = local.physicians
  statement_id  = "AllowExecutionFromCloudWatch-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = module.physician_notes.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule-physician[count.index].arn
}


##################################
# Cloudwatch Events (EventBridge)
##################################
resource "aws_cloudwatch_event_rule" "schedule-physician" {
  count               = local.physicians
  name                = "${var.project_prefix}-schedule-physician-${count.index}"
  description         = "${var.project_prefix}-schedule-physician-${count.index}"
  schedule_expression = "rate(3 minutes)"
}
resource "aws_cloudwatch_event_target" "schedule-physician" {
  count = local.physicians
  rule  = aws_cloudwatch_event_rule.schedule-physician[count.index].name
  arn   = module.physician_notes.lambda_function_arn
  input = "{\"enrolled_patients\":\"5\"}"
}

