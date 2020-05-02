storage_source "dynamodb" {
  table = "defnnn"
  region = "us-west-1"
}

storage_destination "s3" {
  bucket = "defnnn"
  region = "us-west-1"
}
