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


# Random id for naming
resource "random_string" "id" {
  length  = 4
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Create Folder in GCP Organization
resource "google_folder" "abc_app" {
  display_name = "${var.app_folder_name}${random_string.id.result}"
  parent       = "organizations/${var.organization_id}"
}


# Create the management project
resource "google_project" "aw_mgmt_project_id" {
  project_id      = "${var.aw_mgmt_project_id}${random_string.id.result}"
  name            = "Assured Workload Management"
  billing_account = var.billing_account
  folder_id       = google_folder.abc_app.name
  depends_on      = [google_folder.abc_app]
}






# Enable the necessary API services
resource "google_project_service" "aw_api_service" {
  for_each = toset([
    "assuredworkloads.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",

    ## For VPC-SC Add-On
    "cloudresourcemanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "accesscontextmanager.googleapis.com",
  ])

  service = each.key

  project                    = google_project.aw_mgmt_project_id.project_id
  disable_on_destroy         = true
  disable_dependent_services = true
  depends_on                 = [google_project.aw_mgmt_project_id]

}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service" {
  create_duration  = "45s"
  destroy_duration = "45s"
  depends_on = [
    google_project_service.aw_api_service,
  ]
}



resource "google_assured_workloads_workload" "abc_app_aw" {
  provider          = google-beta.service
  billing_account   = "billingAccounts/${var.billing_account}"
  compliance_regime = var.assured_workloads_workload_compliance_regime
  display_name      = var.assured_workloads_workload_display_name
  location          = var.assured_workloads_workload_location
  organization      = var.organization_id

  labels = {
    label-one = var.assured_workloads_label
  }

  provisioned_resources_parent = google_folder.abc_app.name

  depends_on = [
    time_sleep.wait_enable_service,
  ]
}





# Wait delay after AW
resource "time_sleep" "wait_for_aw" {
  create_duration  = "15s"
  destroy_duration = "120s"
  depends_on = [
    google_assured_workloads_workload.abc_app_aw,
  ]
}

# AW delete backup run
resource "null_resource" "del_aw" {

  triggers = {
    project = "${google_project.aw_mgmt_project_id.project_id}"
    aw_id   = "${google_assured_workloads_workload.abc_app_aw.id}"
    id      = "${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  }

  # provisioner "local-exec" {
  #   command = <<EOT
  #gcloud config set project ${google_project.aw_mgmt_project_id.project_id}
  #gcloud config unset project
  #   EOT
  #  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
gcloud config set project ${self.triggers.project}
gcloud resource-manager folders delete ${self.triggers.id} -q
gcloud config unset project
   EOT
  }

# gcloud beta assured workloads delete ${self.triggers.aw_id} -q

  depends_on = [
    time_sleep.wait_for_aw,
  ]

}


# Wait delay after enabling APIs
resource "time_sleep" "wait_null_exec" {
  create_duration  = "10s"
  destroy_duration = "30s"
  depends_on = [
    null_resource.del_aw,
  ]
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_module" {
  create_duration  = "30s"
  destroy_duration = "30s"
  depends_on = [
    module.localhost_function,
    module.event_folder_log_entry,
  ]
}



# Create the Workload Resource Project
resource "google_project" "regular_workload" {
  project_id      = "regular-workload-${random_string.id.result}"
  name            = "Regular Workload"
  billing_account = var.billing_account
  folder_id       = "folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  depends_on      = [time_sleep.wait_module]
}


# Create the Workload CMEK Project
resource "google_project" "cmek_encryption_key" {
  project_id      = "aw-project-enc-key-${random_string.id.result}"
  name            = "cmek project aw"
  billing_account = var.billing_account
  folder_id       = "folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  depends_on      = [time_sleep.wait_module]
}



# Org policy constraint read
data "google_folder_organization_policy" "policy_service_usage" {
  folder     = "folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  constraint = "constraints/gcp.restrictServiceUsage"
  depends_on = [time_sleep.wait_for_aw]
}

# Update the org policy with new service
resource "google_folder_organization_policy" "updated_services_policy" {
  folder     = "folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  constraint = "constraints/gcp.restrictServiceUsage"

  list_policy {
    allow {
      values = local.new_services_list
    }
    inherit_from_parent = false
  }
  depends_on = [time_sleep.wait_for_aw]
}



module "module_aw1" {
  source           = "./module-reg"
  folder_id        = "folders/${google_assured_workloads_workload.abc_app_aw.resources[0].resource_id}"
  organization_id  = var.organization_id
  network_region   = var.network_region
  network_zone     = var.network_zone
  random_string    = random_string.id.result
  vpc_network_name = var.vpc_network_name
  billing_account  = var.billing_account
  project_id       = google_project.regular_workload.project_id
  project_number   = google_project.regular_workload.number
  cmek_project_id  = google_project.cmek_encryption_key.project_id
  project_name     = "Assured Workload"
  bucket_name      = "assured_workload"
  crypto_key_name  = var.crypto_key_name
  key_ring_name    = var.key_ring_name

  depends_on = [
    time_sleep.wait_module,
  ]
}
