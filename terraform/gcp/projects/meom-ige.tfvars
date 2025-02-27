prefix     = "meom-ige"
project_id = "meom-ige-cnrs"

zone   = "us-central1-b"
region = "us-central1"

core_node_machine_type = "n1-highmem-2"

# Single-tenant cluster, network policy not needed
enable_network_policy = false

regional_cluster = false

notebook_nodes = {
  "small" : {
    min : 0,
    max : 20,
    machine_type : "n1-standard-2"
  },
  "medium" : {
    min : 0,
    max : 20,
    machine_type : "n1-standard-8"
  },
  "large" : {
    min : 0,
    max : 20,
    machine_type : "n1-standard-16"
  },
  "very-large" : {
    min : 0,
    max : 20,
    machine_type : "n1-standard-32"
  },
  "huge" : {
    min : 0,
    max : 20,
    machine_type : "n1-standard-64"
  },

}

# Setup a single node pool for dask workers.
#
# A not yet fully established policy is being developed about using a single
# node pool, see https://github.com/2i2c-org/infrastructure/issues/2687.
#
dask_nodes = {
  "worker" : {
    min : 0,
    max : 100,
    machine_type : "n2-highmem-16",
  }
}

user_buckets = {
  "scratch" : {
    "delete_after" : null
  },
  "data" : {
    "delete_after" : null
  }
}

hub_cloud_permissions = {
  "staging" : {
    requestor_pays : true,
    bucket_admin_access : ["scratch", "data"],
    hub_namespace : "staging"
  },
  "prod" : {
    requestor_pays : true,
    bucket_admin_access : ["scratch", "data"],
    hub_namespace : "prod"
  }
}
