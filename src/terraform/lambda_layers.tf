module "lambda_layer" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "4.0.1"
  create_function = false
  create_layer    = true

  layer_name          = "${var.project_prefix}-default"
  description         = "Python dependencies layer (deployed from S3)"
  compatible_runtimes = ["python3.9"]

  runtime = "python3.9" # required to force layers to do pip install

  source_path = [
    {
      path             = "${path.module}/../lambda/layers/default"
      pip_requirements = true
      prefix_in_zip    = "python" # required to get the path correct
    }
  ]

  store_on_s3 = true
  s3_bucket   = module.s3_artifact_repository.s3_bucket_id

}