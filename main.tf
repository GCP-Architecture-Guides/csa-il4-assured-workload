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


data "google_projects" "in_perimeter_folder" {
  filter = "parent.id:${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id} AND lifecycleState:ACTIVE"

}

data "google_project" "in_perimeter_folder" {
  count      = length(data.google_projects.in_perimeter_folder.projects)
  project_id = data.google_projects.in_perimeter_folder.projects[count.index].project_id
}


locals {
  projects     = formatlist("projects/%s", compact(data.google_project.in_perimeter_folder.*.number))
  parent_id    = var.organization_id
  watcher_name = replace("${var.policy_name}-manager-${random_string.id.result}", "_", "-")


  current_services  = length(data.google_folder_organization_policy.policy_service_usage.list_policy) == 0 ? [] : data.google_folder_organization_policy.policy_service_usage.list_policy[0].allow[0].values
  new_services_list = (contains(local.current_services, var.new_services) == false ? setunion(local.current_services, var.new_services) : local.current_services)

}


resource "google_access_context_manager_access_policy" "access_context_manager_policy" {
  provider = google-beta.service
  parent   = "organizations/${var.organization_id}"
  title    = "${var.policy_name}_policy"
  scopes   = ["folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"]
  #["folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"]
  depends_on = [time_sleep.wait_null_exec]
}



resource "google_access_context_manager_access_level" "access_level" {
  provider = google-beta.service
  parent   = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}"
  #"accessPolicies/${google_access_context_manager_access_policy.access-policy.name}"
  name  = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}/accessLevels/${var.policy_name}_levels"
  title = "${var.policy_name}_levels"
  basic {
    conditions {
      members = var.members
      regions = var.enforced_regional_access
    }
  }
  depends_on = [google_access_context_manager_access_policy.access_context_manager_policy]
}


resource "google_access_context_manager_service_perimeter" "service_perimeter" {
  provider = google-beta.service
  parent   = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}"
  #"accessPolicies/${google_access_context_manager_access_policy.access-policy.name}"
  name        = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}/servicePerimeters/${var.perimeter_name}"
  description = "Perimeter_${var.perimeter_name}"
  title       = "${var.perimeter_name}"
  status {
    restricted_services = var.restricted_services
    access_levels       = [google_access_context_manager_access_level.access_level.name]
    resources           = local.projects == null ? [] : local.projects
  }
  depends_on = [google_access_context_manager_access_level.access_level]
}
