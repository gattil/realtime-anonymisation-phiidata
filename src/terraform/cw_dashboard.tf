resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_prefix}-main-dashboard"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "height": 5,
            "width": 24,
            "y": 0,
            "x": 0,
            "properties": {
                "sparkline": true,
                "metrics": [
                    [ "AWS/Firehose", "IncomingRecords", "DeliveryStreamName", "${aws_kinesis_firehose_delivery_stream.delivery_stream_measurements.name}", { "yAxis": "left" } ],
                    [ ".", "SucceedProcessing.Records", ".", "." ],
                    [ ".", "PutRecord.Latency", ".", { "stat": "Average" } ],
                    [ ".", "ThrottledRecords", ".", "." ],
                    [ ".", "FailedConversion.Records", ".", "." ],
                    [ ".", "IncomingBytes", ".", "." ],
                    [ ".", "DeliveryToS3.Records", ".", "." ],
                    [ ".", "DeliveryToS3.Bytes", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 300,
                "start": "-PT1H",
                "end": "P0D",
                "title": "Medical devices"
            }
        },
        {
            "type": "metric",
            "height": 5,
            "width": 24,
            "y": 5,
            "x": 0,
            "properties": {
                "sparkline": true,
                "metrics": [
                    [ "AWS/Firehose", "IncomingRecords", "DeliveryStreamName", "${aws_kinesis_firehose_delivery_stream.delivery_stream_notes.name}", { "yAxis": "left" } ],
                    [ ".", "SucceedProcessing.Records", ".", "." ],
                    [ ".", "PutRecord.Latency", ".", { "stat": "Average" } ],
                    [ ".", "ThrottledRecords", ".", "." ],
                    [ ".", "FailedConversion.Records", ".", "." ],
                    [ ".", "IncomingBytes", ".", "." ],
                    [ ".", "DeliveryToS3.Records", ".", "." ],
                    [ ".", "DeliveryToS3.Bytes", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 300,
                "start": "-PT1H",
                "end": "P0D",
                "title": "Physician annotations"
            }
        }
    ]
}
  EOF
}