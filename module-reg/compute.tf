/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


## NOTE: This provides PoC demo environment for Assured Workload ##
##  This is not built for production workload ##




resource "google_kms_crypto_key_iam_member" "kms_key_access_compute" {
  crypto_key_id = google_kms_crypto_key.kms_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:service-${var.project_number}@compute-system.iam.gserviceaccount.com"
  depends_on = [
    google_kms_crypto_key.kms_key,
    time_sleep.wait_enable_regular_workload_api_service,
  ]

}



# Wait delay 
resource "time_sleep" "wait_compute_iam" {
  create_duration  = "45s"
  destroy_duration = "15s"
  depends_on       = [google_kms_crypto_key_iam_member.kms_key_access_compute]
}

resource "google_compute_disk" "persistant_disk" {
  project = var.project_id
  name    = "persistant-disk"
  type    = "pd-ssd"
  zone    = var.network_zone
  size    = 30
  labels = {
    environment = "p-disk"
  }
  physical_block_size_bytes = 4096
  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.kms_key.id
  }
  depends_on = [
    time_sleep.wait_compute_iam,
  ]
}


#Create the service Account
resource "google_service_account" "def_ser_acc" {
  project      = var.project_id
  account_id   = "sa-service-account"
  display_name = "Compute Service Account"
  depends_on   = [google_project_service.regular_workload_api_service]
}

# Create Compute Instance 
resource "google_compute_instance" "debian_server" {
  project      = var.project_id
  name         = "compute-instance"
  machine_type = "f1-micro"
  zone         = var.network_zone

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
    kms_key_self_link = google_kms_crypto_key.kms_key.id
  }

  network_interface {
    network    = google_compute_network.regular_workload_network.self_link
    subnetwork = google_compute_subnetwork.regular_workload_subnetwork.self_link
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.def_ser_acc.email
    scopes = ["cloud-platform"]
  }


  labels = {
    asset_type = "aw_compute_instance"

  }


  attached_disk {
    source = google_compute_disk.persistant_disk.self_link
  }


  depends_on = [
    google_compute_disk.persistant_disk,
  ]
}


