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

variable "organization_id" {
  description = "(Required)" #The organization for the resource
  type        = string
  default     = "XXXXXXXX"
}


variable "billing_account" {
  description = "(Required)" #Required. Input only. The billing account used for the resources which are direct children of workload. This billing account is initially associated with the resources created as part of Workload creation. After the initial creation of these resources, the customer can change the assigned billing account. The resource name has the form `billingAccounts/{billing_account_id}`. For example, 'billingAccounts/012345-567890-ABCDEF`.
  type        = string
  default     = "XXXXX-XXXXX-XXXXXX"
}


variable "members" {
  description = "An allowed list of members (users, service accounts). The signed-in identity originating the request must be a part of one of the provided members. If not specified, a request may come from any user (logged in/not logged in, etc.). Formats: user:{emailid}, serviceAccount:{emailid}"
  type        = list(string)
  default     = ["user:username@domain.com"]
}

variable "aw_mgmt_project_id" {
  description = "(Required)" #Required. The user-assigned display name of the Workload. When present it must be between 4 to 30 characters. Allowed characters are: lowercase and uppercase letters, numbers, hyphen, and spaces. Example: My Workload
  type        = string
  default     = "aw-mgmt-us-"
}




variable "app_folder_name" {
  description = "(Required)" #Required. The user-assigned display name top folder for application/department/workload. When present it must be between 4 to 30 characters. Allowed characters are: lowercase and uppercase letters, numbers, hyphen, and spaces. Example: My Workload
  type        = string
  default     = "CSA SpringBoard AW"
}




variable "assured_workloads_workload_display_name" {
  description = "(Required)" #Required. The user-assigned display name of the Workload. When present it must be between 4 to 30 characters. Allowed characters are: lowercase and uppercase letters, numbers, hyphen, and spaces. Example: My Workload
  type        = string
  default     = "CSA Assured Workload - IL4"
}

variable "assured_workloads_workload_compliance_regime" {
  description = "(Required)" #Required. Immutable. Compliance Regime associated with this workload. Possible values: COMPLIANCE_REGIME_UNSPECIFIED, IL4, CJIS, FEDRAMP_HIGH, FEDRAMP_MODERATE, US_REGIONAL_ACCESS
  type        = string
  default     = "IL4" #EU_REGIONS_AND_SUPPORT, US_REGIONAL_ACCESS, COMPLIANCE_REGIME_UNSPECIFIED, IL4, CJIS, FEDRAMP_HIGH,FEDRAMP_MODERATE, US_REGIONAL_ACCESS, HIPAA, HITRUST, CA_REGIONS_AND_SUPPORT, ITAR, AU_REGIONS_AND_US_SUPPORT, ASSURED_WORKLOADS_FOR_PARTNERS
}

variable "assured_workloads_workload_location" {
  description = "(Required)" #The location for the resource
  type        = string
  default     = "us" # either a single region or country code
  }

  variable "assured_workloads_label" {
  description = "(Required)" #The location for the resource
  type        = string
  default     = "aw-il4" # either a single region or country code
  }



variable "network_region" {
  type    = string
  default = "us-west1"
}

variable "vpc_network_name" {
  type    = string
  default = "vpc-network"
}

variable "network_zone" {
  type    = string
  default = "us-west1-b"
}


variable "crypto_key_name" {
  type    = string
  default = "crypto_key"
}

variable "key_ring_name" {
  type    = string
  default = "ring"
}



variable "policy_name" {
  description = "The policy's name."
  type        = string
  default     = "automatic_folder"
}





variable "perimeter_name" {
  description = "Name of perimeter."
  type        = string
  default     = "regular_perimeter"
}

variable "restricted_services" {
  description = "List of services to restrict."
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
  ]
}

variable "new_services" {
  description = "List of new services to restrict that are recently approved to assured workloads but not allowed default"
  type        = set(string)
  default = [
    "bigquery.googleapis.com",
  ]
}


variable "enforced_regional_access" {
    description = "CountryRegion "
    type = list(string)
    default = [
        "US", # USA
        "CA", # Canada
        "UM", #  US Minor Outlying Islands
        ]
}
