resource "aws_glue_catalog_database" "redacted-db" {
  name = "${var.project_prefix}-db"
}

resource "aws_glue_catalog_table" "redacted-db-measurements-anonymised" {
  name          = "measurements-anonymised"
  database_name = aws_glue_catalog_database.redacted-db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "UNCOMPRESSED"
  }

  storage_descriptor {
    location      = "s3://${module.s3_data_redacted.s3_bucket_id}/measurements/redacted/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "patient_uuid"
      type = "varchar(35)"
    }
    columns {
      name = "recording_time"
      type = "string"
    }
    columns {
      name = "location_lat"
      type = "string"
    }
    columns {
      name = "location_lon"
      type = "string"
    }
    columns {
      name = "measurement_schema"
      type = "string"
    }
    columns {
      name = "measurement_insuline"
      type = "string"
    }
    columns {
      name = "measurement_glucose"
      type = "string"
    }
    columns {
      name = "measurement_temp"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "redacted-db-notes-anonymised" {
  name          = "notes-anonymised"
  database_name = aws_glue_catalog_database.redacted-db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "UNCOMPRESSED"
  }

  storage_descriptor {
    location      = "s3://${module.s3_data_redacted.s3_bucket_id}/notes/redacted/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "patient_uuid"
      type = "varchar(35)"
    }
    columns {
      name = "recording_time"
      type = "string"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "birthdate"
      type = "string"
    }
    columns {
      name = "ssn"
      type = "string"
    }
    columns {
      name = "address"
      type = "string"
    }
    columns {
      name = "gender"
      type = "string"
    }
    columns {
      name = "physician_annotation"
      type = "varchar(850)"
    }
  }
}
