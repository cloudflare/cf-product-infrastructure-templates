terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_kms_key_ring" "cloudflare_cds_kms_keyring" {
  name     = var.kms_keyring_name
  project  = var.project_id
  location = "global"

}