data aws_iam_policy_document "medical_device" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
  }

}

module "medical_device" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.1"

  function_name = "${var.project_prefix}-medical-device"
  description   = "Generate S3 pre-signed URL to upload file"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "../lambda/functions/medical_device/src"

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
  policy_json                   = data.aws_iam_policy_document.medical_device.json
  tracing_mode                  = "Active"

  environment_variables = {
    delivery_stream = aws_kinesis_firehose_delivery_stream.delivery_stream_measurements.name
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_medical_devices" {
  count         = local.devices
  statement_id  = "AllowExecutionFromCloudWatch-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = module.medical_device.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule-medical-device[count.index].arn
}

##################################
# Cloudwatch Events (EventBridge)
##################################

resource "aws_cloudwatch_event_rule" "schedule-medical-device" {
  count               = local.devices
  name                = "${var.project_prefix}-medical-device-${count.index}"
  description         = "${var.project_prefix}-medical-device-${count.index}"
  schedule_expression = "rate(1 minute)"
}
resource "aws_cloudwatch_event_target" "schedule-medical-device" {
  count = local.devices
  rule  = aws_cloudwatch_event_rule.schedule-medical-device[count.index].name
  arn   = module.medical_device.lambda_function_arn
  input = "{\"enrolled_patients\":\"20\"}"
}


