/**
 * Copyright 2022 Google LLC
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

/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_number}"
admin_upn_fqn               = "${var.gcp_account_name}"
location                    = "${var.gcp_region}"
location_multi              = "${var.gcp_multi_region}"
zone                        = "${var.gcp_zone}"
umsa                        = "lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"

dpms_nm                     = "lab-dpms-${local.project_nbr}"
dew_spark_bucket            = "lab-spark-bucket-${local.project_nbr}"
dew_spark_bucket_fqn        = "gs://dew-lab-spark-${local.project_nbr}"
dew_vpc_nm                  = "lab-vpc-${local.project_nbr}"
dew_subnet_nm               = "lab-snet"
dew_subnet_cidr             = "10.0.0.0/16"

dew_raw_ds                  = "oda_raw"
dew_data_bucket_raw         = "oda-raw-data-${local.project_nbr}"
dew_code_bucket             = "oda-raw-code-${local.project_nbr}"
dew_notebook_bucket         = "oda-raw-notebook-${local.project_nbr}"
dew_model_bucket            = "oda-raw-model-${local.project_nbr}"
dew_bundle_bucket           = "oda-raw-model-mleap-bundle-${local.project_nbr}"
dew_metrics_bucket          = "oda-raw-model-metrics-${local.project_nbr}"

dew_curated_ds              = "oda_curated"
dew_consumption_ds          = "oda_consumption"
dew_curated_ml_ds           = "oda_model_mart"
dew_data_bucket_curated     = "oda-curated-data-${local.project_nbr}"
dew_data_bucket_consumption = "oda-consumption-data-${local.project_nbr}"


CC_GMSA_FQN                 = "service-${local.project_nbr}@cloudcomposer-accounts.iam.gserviceaccount.com"
GCE_GMSA_FQN                = "${local.project_nbr}-compute@developer.gserviceaccount.com"
CLOUD_COMPOSER2_IMG_VERSION = "${var.cloud_composer_image_version}"
bq_connector_jar_gcs_uri    = "${var.bq_connector_jar_gcs_uri}"
}

/******************************************
1. Enable Google APIs in parallel
 *****************************************/

 module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                     = var.project_id
  enable_apis                 = true

  activate_apis = [
    "compute.googleapis.com",
    "dataproc.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "storage-component.googleapis.com",
    "bigquerystorage.googleapis.com",
    "datacatalog.googleapis.com",
    "dataplex.googleapis.com",
    "bigquery.googleapis.com" ,
    "cloudresourcemanager.googleapis.com",
    "cloudidentity.googleapis.com",
    "storage.googleapis.com",
    "composer.googleapis.com",
    "metastore.googleapis.com",
    "orgpolicy.googleapis.com",
    "dlp.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dataplex.googleapis.com",
    "datacatalog.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "datapipelines.googleapis.com",
    "cloudscheduler.googleapis.com",
    "datalineage.googleapis.com"
    ]

  disable_services_on_destroy = false
}
/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
}

/******************************************
2. Project-scoped Org Policy Updates
*****************************************/

resource "google_project_organization_policy" "bool-policies" {
  for_each = {
    "compute.requireOsLogin" : false,
    "compute.disableSerialPortLogging" : false,
    "compute.requireShieldedVm" : false
  }
  project    = var.project_id
  constraint = format("constraints/%s", each.key)
  boolean_policy {
    enforced = each.value
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

resource "google_project_organization_policy" "list_policies" {
  for_each = {
    "compute.vmCanIpForward" : true,
    "compute.vmExternalIpAccess" : true,
    "compute.restrictVpcPeering" : true
  }
  project     = var.project_id
  constraint = format("constraints/%s", each.key)
  list_policy {
    allow {
      all = each.value
    }
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_apis_and_org_policies" {
  create_duration = "60s"

  depends_on = [
    google_project_organization_policy.bool-policies,
    google_project_organization_policy.list_policies,
    time_sleep.sleep_after_activate_service_apis
  ]
}

/******************************************
3. Create User Managed Service Account 
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for Dataplex lab"
   depends_on = [time_sleep.sleep_after_apis_and_org_policies]
}

/******************************************
4a. Grant IAM roles to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/metastore.admin",
    "roles/metastore.editor",
    "roles/dataproc.worker",
    "roles/dataproc.editor",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin",
    "roles/viewer",
    "roles/composer.worker",
    "roles/composer.admin"
  ]
  depends_on = [
    module.umsa_creation
  ]
}

# IAM role grants to Google Managed Service Account for Cloud Composer 2
module "gmsa_role_grants_cc" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.CC_GMSA_FQN}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/composer.ServiceAgentV2Ext",
  ]
  depends_on = [
    module.umsa_role_grants
  ]
}

# IAM role grants to Google Managed Service Account for Compute Engine (for Cloud Composer 2 to download images)
module "gmsa_role_grants_gce" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.GCE_GMSA_FQN}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/editor",
  ]
  depends_on = [
    module.umsa_role_grants
  ]
}


/******************************************************
5. Grant Service Account Impersonation privilege to yourself/Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"
  service_accounts = ["${local.umsa_fqn}"]
  project          = local.project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}"
    ]

  }
  depends_on = [
    module.umsa_creation
  ]
}

/******************************************************
6. Grant IAM roles to Admin User/yourself
 ******************************************************/

module "administrator_role_grants" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = ["${local.project_id}"]
  mode     = "additive"

  bindings = {
    "roles/storage.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/metastore.admin" = [

      "user:${local.admin_upn_fqn}",
    ]
    "roles/dataproc.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.user" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.dataEditor" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.jobUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.environmentAndStorageObjectViewer" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
     "roles/compute.networkAdmin" = [
      "user:${local.admin_upn_fqn}",
    ]
  }
  depends_on = [
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin
  ]
  }

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_identities_permissions" {
  create_duration = "120s"
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin,
    module.administrator_role_grants,
    module.gmsa_role_grants_cc,
    module.gmsa_role_grants_gce
  ]
}

/************************************************************************
7. Create VPC network & subnet 
 ***********************************************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
  project_id                             = local.project_id
  network_name                           = local.dew_vpc_nm
  routing_mode                           = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.dew_subnet_nm}"
      subnet_ip             = "${local.dew_subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = local.dew_subnet_cidr
      subnet_private_access = true
    }
  ]
  depends_on = [
    time_sleep.sleep_after_identities_permissions
  ]
}


/******************************************
8. Create Firewall rules 
 *****************************************/

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = local.project_id 
  name      = "allow-intra-snet-ingress-to-any"
  network   = local.dew_vpc_nm
  direction = "INGRESS"
  source_ranges = [local.dew_subnet_cidr]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within subnet on all ports, all protocols"
  depends_on = [
    module.vpc_creation
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_firewall_creation" {
  create_duration = "120s"
  depends_on = [
    module.vpc_creation,
    google_compute_firewall.allow_intra_snet_ingress_to_any
  ]
}

/******************************************
9. Create Storage bucket 
 *****************************************/

resource "google_storage_bucket" "dew_spark_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_spark_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_data_bucket_raw_creation" {
  project                           = local.project_id 
  name                              = local.dew_data_bucket_raw
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_code_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_code_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_notebook_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_notebook_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_model_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_model_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_metrics_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_metrics_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_bundle_bucket_creation" {
  project                           = local.project_id 
  name                              = local.dew_bundle_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_data_bucket_curated_creation" {
  project                           = local.project_id 
  name                              = local.dew_data_bucket_curated
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "dew_data_bucket_consumption_creation" {
  project                           = local.project_id 
  name                              = local.dew_data_bucket_consumption
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}


/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "60s"
  depends_on = [
    google_storage_bucket.dew_data_bucket_raw_creation,
    google_storage_bucket.dew_code_bucket_creation,
    google_storage_bucket.dew_notebook_bucket_creation,
    google_storage_bucket.dew_spark_bucket_creation,
    google_storage_bucket.dew_model_bucket_creation,
    google_storage_bucket.dew_metrics_bucket_creation,
    google_storage_bucket.dew_bundle_bucket_creation,
    google_storage_bucket.dew_data_bucket_curated_creation,
    google_storage_bucket.dew_data_bucket_consumption_creation

  ]
}

/******************************************
10. Copy of datasets, scripts and notebooks to buckets
 ******************************************/

variable "notebooks_to_upload" {
  type = map(string)
  default = {
    "../notebooks/chicago-crimes-analysis/chicago-crimes-analytics.ipynb" = "chicago-crimes-analysis/chicago-crimes-analytics.ipynb",
    "../notebooks/icecream-sales-forecasting/icecream-sales-forecasting.ipynb" = "icecream-sales-forecasting/icecream-sales-forecasting.ipynb",
    "../notebooks/telco-customer-churn-prediction/preprocessing.ipynb" = "telco-customer-churn-prediction/preprocessing.ipynb",
    "../notebooks/telco-customer-churn-prediction/model_training.ipynb" = "telco-customer-churn-prediction/model_training.ipynb",
    "../notebooks/telco-customer-churn-prediction/hyperparameter_tuning.ipynb" = "telco-customer-churn-prediction/hyperparameter_tuning.ipynb",
    "../notebooks/telco-customer-churn-prediction/batch_scoring.ipynb" = "telco-customer-churn-prediction/batch_scoring.ipynb",  
    "../notebooks/retail-transactions-anomaly-detection/retail-transactions-anomaly-detection.ipynb" = "retail-transactions-anomaly-detection/retail-transactions-anomaly-detection.ipynb",
  }
}

resource "google_storage_bucket_object" "upload_to_gcs_notebooks" {
  for_each = var.notebooks_to_upload
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = "${local.dew_notebook_bucket}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]

}

variable "datasets_to_upload" {
  type = map(string)
  default = {
    
    "../datasets/icecream-sales-forecasting/icecream_sales.csv" = "icecream-sales-forecasting/icecream_sales.csv",
    "../datasets/telco-customer-churn-prediction/customer_churn_score_data.csv" = "telco-customer-churn-prediction/customer_churn_score_data.csv",
    "../datasets/telco-customer-churn-prediction/customer_churn_train_data.csv" = "telco-customer-churn-prediction/customer_churn_train_data.csv",
    "../datasets/retail-transactions-anomaly-detection/sales.parquet" = "retail-transactions-anomaly-detection/sales.parquet"  
  }
}

resource "google_storage_bucket_object" "upload_to_gcs_datasets" {
  for_each = var.datasets_to_upload
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = "${local.dew_data_bucket_raw}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]

}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_network_and_storage_steps" {
  create_duration = "120s"
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
      time_sleep.sleep_after_bucket_creation,
      google_storage_bucket_object.upload_to_gcs_datasets,
      google_storage_bucket_object.upload_to_gcs_notebooks

  ]
}

/******************************************
11. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_raw_ds_creation" {
  dataset_id                  = local.dew_raw_ds
  location                    = local.location_multi
}

resource "google_bigquery_dataset" "bq_curated_ds_creation" {
  dataset_id                  = local.dew_curated_ds
  location                    = local.location_multi
}

resource "google_bigquery_dataset" "bq_consumption_ds_creation" {
  dataset_id                  = local.dew_consumption_ds
  location                    = local.location_multi
}


/******************************************
12. Dataproc Metastore with gRPC endpoint
******************************************/

resource "google_dataproc_metastore_service" "datalake_metastore" {
  provider      = google-beta
  service_id    = local.dpms_nm
  location      = local.location
  tier          = "DEVELOPER"

 maintenance_window {
    hour_of_day = 2
    day_of_week = "SUNDAY"
  }

 hive_metastore_config {
    version = "3.1.2"
    endpoint_protocol = "GRPC"
    
  }
  depends_on = [
    module.administrator_role_grants,
    time_sleep.sleep_after_network_and_storage_steps
  ]
}

/******************************************
13. Cloud Composer
******************************************/






/******************************************
DONE
******************************************/
