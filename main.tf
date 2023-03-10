terraform {
  required_providers {
    skysql = {
      source = "mariadb-corporation/skysql"
      version ="1.0.0"
    }
  }
}


provider "skysql" {}

# Retrieve the list of available versions for each topology like standalone, masterslave, xpand-direct etc
data "skysql_versions" "default" {}


# Filter the list of versions to only include  versions for the standalone topology
locals {
  sky_versions_filtered = [
    for item in data.skysql_versions.default.versions : item if item.topology == "xpand-direct"
  ]
}

# Retrieve the list of projects. Project is a way of grouping the services.
# Note: Next release will make project_id optional in the create service api
data "skysql_projects" "default" {}

output "skysql_projects" {
  value = data.skysql_projects.default
}

# Create a service
resource "skysql_service" master {
  project_id     = "xxxx-xxxx-xxxx-xxxx-xxxx"
  service_type   = "transactional"
  topology       = "xpand-direct"
  cloud_provider = "aws"
  region         = "us-west-2"
  name           = "customer777-xpand1"
  architecture   = "amd64"
  nodes          = 1
  size           = "sky-2x8"
  storage        = 100
  ssl_enabled    = false
  version        = local.sky_versions_filtered[0].name
  endpoint_mechanism      = "privatelink"
  endpoint_allowed_accounts = ["xxxxxxxxxxx"]
  # The service create is an asynchronous operation.
  # if you want to wait for the service to be created set wait_for_creation to true
  wait_for_creation = true
  wait_for_deletion = true
}


# Retrieve the service default credentials.
# When the service is created please change the default credentials
data "skysql_credentials" "default" {
    service_id = skysql_service.master.id
}

# Retrieve the service details
data "skysql_service" "default" {
  service_id = skysql_service.master.id
}

# Show the service details
output "skysql_service" {
  value = data.skysql_service.default
}

# Show the service credentials
output "skysql_credentials" {
  value = data.skysql_credentials.default
  sensitive = true
}


# Example how you can generate a command line for the database connection
output "skysql_cmd" {
 value = "mariadb --host ${data.skysql_service.default.fqdn} --port 3306 --user ${data.skysql_service.default.service_id} -p "
}
