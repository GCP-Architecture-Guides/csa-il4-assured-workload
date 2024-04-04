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


# Create the host network
resource "google_compute_network" "regular_workload_network" {
  project                 = var.project_id
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
  description             = "${var.project_name} Network"
  depends_on              = [time_sleep.wait_enable_regular_workload_api_service]
}

# Create custom subnetwork
resource "google_compute_subnetwork" "regular_workload_subnetwork" {
  name          = "host-network-${var.network_region}"
  ip_cidr_range = "192.168.0.0/24"
  region        = var.network_region
  project       = var.project_id
  network       = google_compute_network.regular_workload_network.self_link
  # Enabling VPC flow logs
  #   log_config {
  #       aggregation_interval = "INTERVAL_10_MIN"
  #       flow_sampling        = 0.5
  #       metadata             = "INCLUDE_ALL_METADATA"
  # }
  private_ip_google_access = true
  depends_on = [
    google_compute_network.regular_workload_network,
  ]
}


# Enable SSH through IAP
resource "google_compute_firewall" "allow_iap_proxy" {
  name      = "allow-iap-proxy"
  network   = google_compute_network.regular_workload_network.self_link
  project   = var.project_id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  depends_on = [
    google_compute_network.regular_workload_network
  ]
}