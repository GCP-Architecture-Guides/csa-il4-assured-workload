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



module "event_folder_log_entry" {
  source = "terraform-google-modules/event-function/google//modules/event-folder-log-entry"
  #  version = "~> 2.1"

  filter     = <<EOF
resource.type="project" AND
protoPayload.serviceName="cloudresourcemanager.googleapis.com" AND
(protoPayload.methodName="CreateProject" OR protoPayload.methodName="DeleteProject" OR protoPayload.methodName="UpdateProject")
EOF
  name       = local.watcher_name
  project_id = google_project.aw_mgmt_project_id.project_id
  folder_id  = google_assured_workloads_workload.abc_app_aw.resources[0].resource_id
  depends_on = [time_sleep.wait_null_exec]
}


resource "google_service_account" "watcher" {
  project = google_project.aw_mgmt_project_id.project_id

  account_id   = local.watcher_name
  display_name = local.watcher_name
}



# Add required roles to the service accounts
resource "google_project_iam_member" "proj_editor" {
  project    = google_project.aw_mgmt_project_id.project_id
  role       = "roles/editor"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}



resource "google_organization_iam_member" "access_context_manager_admin" {
  org_id     = var.organization_id
  role       = "roles/accesscontextmanager.policyAdmin"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}


resource "google_folder_iam_member" "folder_logging" {
  folder     = google_folder.abc_app.name
  role       = "roles/logging.configWriter"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}


resource "google_folder_iam_member" "folder_view" {
  folder     = google_folder.abc_app.name
  role       = "roles/resourcemanager.folderViewer"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}


resource "google_organization_iam_member" "aw_read" {
  org_id     = var.organization_id
  role       = "roles/assuredworkloads.admin"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}

resource "google_organization_iam_member" "folder_editor" {
  org_id     = var.organization_id
  role       = "roles/resourcemanager.folderEditor"
  member     = "serviceAccount:${google_service_account.watcher.email}"
  depends_on = [google_service_account.watcher]
}


module "localhost_function" {

  source = "terraform-google-modules/event-function/google"

  description = "Adds projects to VPC service permiterer."
  entry_point = "handler"

  environment_variables = {
    FOLDER_ID = "${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"

  }

  event_trigger    = module.event_folder_log_entry.function_event_trigger
  name             = local.watcher_name
  project_id       = google_project.aw_mgmt_project_id.project_id
  region           = var.network_region
  source_directory = abspath(path.module)
  # "${path.module}/watcher_function_source"
  #abspath(path.module)
  runtime               = "python37"
  available_memory_mb   = 2048
  timeout_s             = 540
  service_account_email = google_service_account.watcher.email
  ingress_settings      = "ALLOW_INTERNAL_AND_GCLB"
  depends_on            = [google_access_context_manager_service_perimeter.service_perimeter]
}


