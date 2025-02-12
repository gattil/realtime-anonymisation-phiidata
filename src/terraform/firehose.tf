data aws_iam_policy_document "delivery_stream_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = [
      "${module.s3_data_raw.s3_bucket_arn}/*",
      "${module.s3_data_redacted.s3_bucket_arn}/*",
      module.s3_data_raw.s3_bucket_arn,
      module.s3_data_redacted.s3_bucket_arn
    ]
  }
  statement {
    actions = [
      "glue:*",
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    actions = [
      "lambda:InvokeFunction",
      "logs:CreateLogStream"
    ]
    effect    = "Allow"
    resources = [
      module.redact_pii_data.lambda_function_arn
    ]
  }
}

data "aws_iam_policy_document" "delivery_stream_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delivery_stream_role" {
  name               = "${var.project_prefix}-delivery-stream-role"
  assume_role_policy = data.aws_iam_policy_document.delivery_stream_assume_role_policy.json
  inline_policy {
    name   = "AllowFirehoseToOperate"
    policy = data.aws_iam_policy_document.delivery_stream_policy.json
  }
}


resource "aws_cloudwatch_log_group" "delivery_stream" {
  name              = "/${var.project_prefix}/fh"
  retention_in_days = 1
  encryption        = true
}

resource "aws_cloudwatch_log_stream" "delivery_stream" {
  name           = "default"
  log_group_name = aws_cloudwatch_log_group.delivery_stream.name
}


resource "aws_kinesis_firehose_delivery_stream" "delivery_stream_measurements" {
  name        = "${var.project_prefix}-delivery-stream-measurements"
  destination = "extended_s3"
  #type = "DirectPut"

  extended_s3_configuration {
    role_arn   = aws_iam_role.delivery_stream_role.arn
    bucket_arn = module.s3_data_redacted.s3_bucket_arn

    compression_format  = "UNCOMPRESSED"
    prefix              = "measurements/redacted/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/!{timestamp:HH}/"
    error_output_prefix = "measurements/errors/!{firehose:random-string}/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    processing_configuration {
      enabled = "true"
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.redact_pii_data.lambda_function_arn
        }
        parameters {
          parameter_name  = "NumberOfRetries"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "RoleArn"
          parameter_value = aws_iam_role.delivery_stream_role.arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "1"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    buffer_interval = 300
    buffer_size     = 128

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.delivery_stream.name
      log_stream_name = aws_cloudwatch_log_stream.delivery_stream.id
    }

    s3_backup_mode = "Enabled"
    s3_backup_configuration {
      bucket_arn      = module.s3_data_raw.s3_bucket_arn
      role_arn        = aws_iam_role.delivery_stream_role.arn
      buffer_interval = 240
      buffer_size     = 1

      cloudwatch_logging_options {
        enabled         = "true"
        log_group_name  = aws_cloudwatch_log_group.delivery_stream.name
        log_stream_name = aws_cloudwatch_log_stream.delivery_stream.id
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "UNCOMPRESSED"
          }
        }
      }
      schema_configuration {
        database_name = aws_glue_catalog_database.redacted-db.name
        role_arn      = aws_iam_role.delivery_stream_role.arn
        table_name    = aws_glue_catalog_table.redacted-db-measurements-anonymised.name
      }
    }

  }
}


resource "aws_kinesis_firehose_delivery_stream" "delivery_stream_notes" {
  name        = "${var.project_prefix}-delivery-stream-notes"
  destination = "extended_s3"
  #type = "DirectPut"

  extended_s3_configuration {
    role_arn   = aws_iam_role.delivery_stream_role.arn
    bucket_arn = module.s3_data_redacted.s3_bucket_arn

    compression_format  = "UNCOMPRESSED"
    prefix              = "notes/redacted/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/!{timestamp:HH}/"
    error_output_prefix = "notes/errors/!{firehose:random-string}/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    processing_configuration {
      enabled = "true"
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.redact_pii_data.lambda_function_arn
        }
        parameters {
          parameter_name  = "NumberOfRetries"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "RoleArn"
          parameter_value = aws_iam_role.delivery_stream_role.arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "1"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    buffer_interval = 300
    buffer_size     = 128

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.delivery_stream.name
      log_stream_name = aws_cloudwatch_log_stream.delivery_stream.id
    }

    s3_backup_mode = "Enabled"
    s3_backup_configuration {
      bucket_arn      = module.s3_data_raw.s3_bucket_arn
      role_arn        = aws_iam_role.delivery_stream_role.arn
      buffer_interval = 240
      buffer_size     = 1

      cloudwatch_logging_options {
        enabled         = "true"
        log_group_name  = aws_cloudwatch_log_group.delivery_stream.name
        log_stream_name = aws_cloudwatch_log_stream.delivery_stream.id
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "UNCOMPRESSED"
          }
        }
      }
      schema_configuration {
        database_name = aws_glue_catalog_database.redacted-db.name
        role_arn      = aws_iam_role.delivery_stream_role.arn
        table_name    = aws_glue_catalog_table.redacted-db-notes-anonymised.name
      }
    }

  }
}


