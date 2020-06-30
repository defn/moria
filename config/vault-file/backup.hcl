storage_source "file" {
  path = "backup/vault-file"
}

storage_destination "s3" {
  bucket = "defnnnn"
  region = "us-west-1"
}
