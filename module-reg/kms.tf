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


# Create key ring
resource "google_kms_key_ring" "keyring" {
  name     = var.key_ring_name
  location = var.network_region
  project  = var.cmek_project_id

  depends_on = [time_sleep.wait_enable_cmek_api_service]

}



# Cretae crypto key
resource "google_kms_crypto_key" "kms_key" {
  name            = var.crypto_key_name
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "10368000s" #120 days

  lifecycle {
    prevent_destroy = false ## For actual workload, change to true
  }
  depends_on = [google_kms_key_ring.keyring]
}
