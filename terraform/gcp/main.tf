terraform {
  required_version = "~> 1.5"

  backend "gcs" {}
  required_providers {
    google = {
      # ref: https://registry.terraform.io/providers/hashicorp/google/latest
      source  = "google"
      version = "~> 4.55"
    }
    google-beta = {
      # ref: https://registry.terraform.io/providers/hashicorp/google-beta/latest
      source  = "google-beta"
      version = "~> 4.55"
    }
    kubernetes = {
      # ref: https://registry.terraform.io/providers/hashicorp/kubernetes/latest
      source  = "hashicorp/kubernetes"
      version = "~> 2.18"
    }
    # Used to decrypt sops encrypted secrets containing PagerDuty keys
    sops = {
      # ref: https://registry.terraform.io/providers/carlpett/sops/latest
      source  = "carlpett/sops"
      version = "~> 0.7.2"
    }
  }
}

provider "google" {
  # This was configured without full understanding of the implications to
  # resolve the following error:
  #
  # Error: Error when reading or editing BillingBudget "...": googleapi: Error 403: Your application has authenticated using end user credentials from the Google Cloud SDK or Google Cloud Shell which are not supported by the billingbudgets.googleapis.com. We recommend configuring the billing/quota_project setting in gcloud or using a service account through the auth/impersonate_service_account setting. For more information about service accounts and how to use them in your application, see https://cloud.google.com/docs/authentication/. If you are getting this error with curl or similar tools, you may need to specify 'X-Goog-User-Project' HTTP header for quota and billing purposes. For more information regarding 'X-Goog-User-Project' header, please check https://cloud.google.com/apis/docs/system-parameters.
  #
  # Configuration reference:
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#user_project_override
  #
  # FIXME: Erik concluded that billing_project could be set to var.project_id at
  #        least for one cluster, but it required that the project where the
  #        cluster lived first enabled the GCP API: https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com
  #
  #        So, we should probably not reference a new variable here, but enable
  #        the API for all our existing GCP projects and new GCP projects, and
  #        then reference var.project_id instead.
  #
  #        But who knows, its hard to understand whats going on.
  #
  user_project_override = true
  billing_project       = var.billing_project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  # From https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started#provider-setup
  host  = "https://${google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )
}

