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

# Wait delay after after project destroy
resource "time_sleep" "wait_reg_project_creation" {

  create_duration  = "15s"
  destroy_duration = "15s"
}



# Enable the necessary API services
resource "google_project_service" "regular_workload_api_service" {
  for_each = toset([
    "logging.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com", # Allow for BQ workload
  ])

  service = each.key

  project                    = var.project_id
  disable_on_destroy         = true
  disable_dependent_services = true
  depends_on                 = [time_sleep.wait_reg_project_creation]
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_regular_workload_api_service" {
  depends_on       = [google_project_service.regular_workload_api_service]
  create_duration  = "45s"
  destroy_duration = "45s"
}
