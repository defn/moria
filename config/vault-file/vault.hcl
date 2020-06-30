ui = true

storage "file" {
  path = "/vault/vault-file"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

disable_mlock = true
