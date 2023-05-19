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


output "_01_assured_workload_folder_id" {
  value = google_assured_workloads_workload.abc_app_aw.resources[0].resource_id
}


output "_02_assured_workload_folder_name" {
  value = google_assured_workloads_workload.abc_app_aw.display_name
}


output "_03_assured_workload_compliance_regime" {
  value = google_assured_workloads_workload.abc_app_aw.compliance_regime
}

output "_04_assured_workload_kms_project_id" {
  value = "aw-project-enc-key-${random_string.id.result}"
}

output "_05_assured_workload_id" {
  value = google_assured_workloads_workload.abc_app_aw.id
}

/*
output "_10_policy_service_usage_attributes" {
  value = data.google_folder_organization_policy.policy_service_usage.list_policy[0].allow[0].values
}
# data.google_folder_organization_policy.policy_service_usage.list_policy[0].allow[0].values


output "_09_policy_service_usage_attributes" {
  value = data.google_folder_organization_policy.policy_service_usage.list_policy
}




output "_11_policy_service_usage_attributes" {
  value = local.new_services_list
}



output "_06_project_attributes" {
  value = google_folder.abc_app
}

output "_07_aw_attributes" {
  value = google_assured_workloads_workload.abc_app_aw
}


output "_08_aw_attributes" {
  value = data.google_projects.in_perimeter_folder
}


*/