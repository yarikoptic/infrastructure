prefix                 = "linked-earth"
project_id             = "linked-earth-hubs"
zone                   = "us-central1-c"
region                 = "us-central1"
core_node_machine_type = "e2-highmem-4"
enable_network_policy  = true

# Setup a filestore for in-cluster NFS
enable_filestore      = true
filestore_capacity_gb = 1024

user_buckets = {
  "scratch-staging" : {
    "delete_after" : 7
  },
  "scratch" : {
    "delete_after" : 7
  }
}

# Setup notebook node pools
notebook_nodes = {
  "small" : {
    min : 0,
    max : 100,
    machine_type : "e2-highmem-4"
  },
  "medium" : {
    min : 0,
    max : 100,
    machine_type : "e2-highmem-16"
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

hub_cloud_permissions = {
  "staging" : {
    requestor_pays : false,
    bucket_admin_access : ["scratch-staging"],
    hub_namespace : "staging"
  },
  "prod" : {
    requestor_pays : false,
    bucket_admin_access : ["scratch"],
    hub_namespace : "prod"
  }
}

container_repos = []
