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

## Gcloud command - "bq show --encryption_service_account --project_id=PROJECT_ID"


# Trigger BQ service agent
resource "null_resource" "bq_encryption_s_agent" {
  triggers = {
    local_project = "${var.project_id}"
  }

  provisioner "local-exec" {
    command     = <<EOT
    bq show --encryption_service_account --project_id=${var.project_id}
    EOT
    working_dir = path.module
  }

  depends_on = [
    time_sleep.wait_enable_regular_workload_api_service,
  ]
}



# Wait delay after after project destroy
resource "time_sleep" "wait_bq_a_agent" {
  create_duration = "15s"
  #  destroy_duration = "15s"
  depends_on = [null_resource.bq_encryption_s_agent]
}


resource "google_kms_crypto_key_iam_member" "kms_key_access_bq" {
  crypto_key_id = google_kms_crypto_key.kms_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${var.project_number}@bigquery-encryption.iam.gserviceaccount.com"

  depends_on = [
    google_kms_crypto_key.kms_key,
    time_sleep.wait_bq_a_agent,
  ]
}


# Wait delay after after project destroy
resource "time_sleep" "wait_bq_iam" {
  create_duration  = "45s"
  destroy_duration = "15s"
  depends_on       = [google_kms_crypto_key_iam_member.kms_key_access_bq]
}




# Create dataset in bigquery
resource "google_bigquery_dataset" "clear_dataset" {
  dataset_id                 = "clear_dataset_${var.random_string}"
  location                   = var.network_region
  project                    = var.project_id
  delete_contents_on_destroy = true
  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.kms_key.id
  }

  depends_on = [
    time_sleep.wait_bq_iam,
  ]
}





# Create table in bigquery
resource "google_bigquery_table" "clear_table" {
  dataset_id          = google_bigquery_dataset.clear_dataset.dataset_id
  project             = var.project_id
  table_id            = "clear-data"
  description         = "This table contain clear text sensitive data"
  deletion_protection = false
  depends_on          = [google_bigquery_dataset.clear_dataset]
}

