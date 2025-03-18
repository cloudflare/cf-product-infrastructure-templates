terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_kms_crypto_key" "cloudflare_cds_kms_key" {
  name            = var.kms_key_name
  key_ring        = var.kms_keyring_id
  rotation_period = "7776000s" # 90 days
}
