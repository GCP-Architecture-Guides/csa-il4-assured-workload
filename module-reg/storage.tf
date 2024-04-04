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

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}


# Wait delay after after project destroy
resource "time_sleep" "wait_gcs_agent" {
  create_duration = "15s"
  #  destroy_duration = "15s"
  depends_on = [data.google_storage_project_service_account.gcs_account]
}



resource "google_kms_crypto_key_iam_member" "kms_key_access_storge" {
  crypto_key_id = google_kms_crypto_key.kms_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  depends_on = [
    time_sleep.wait_enable_regular_workload_api_service,
    time_sleep.wait_gcs_agent
  ]
}


# Wait delay after after project destroy
resource "time_sleep" "wait_storage_iam" {
  create_duration  = "45s"
  destroy_duration = "15s"
  depends_on       = [google_kms_crypto_key_iam_member.kms_key_access_storge]
}



#Creating Staging/QA storage bucket
resource "google_storage_bucket" "regular_workload_bucket_name" {
  name                        = "${var.bucket_name}_${var.random_string}"
  location                    = var.network_region
  force_destroy               = true
  project                     = var.project_id
  uniform_bucket_level_access = true
  encryption {
    default_kms_key_name = google_kms_crypto_key.kms_key.id
  }
  depends_on = [
    time_sleep.wait_storage_iam,
    google_kms_crypto_key_iam_member.kms_key_access_storge,
  ]
}

