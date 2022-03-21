// Exports an eksctl config file for carbonplan cluster
local ng = import "./libsonnet/nodegroup.jsonnet";

// place all cluster nodes here
local clusterRegion = "us-west-2";
local masterAzs = ["us-west-2a", "us-west-2b", "us-west-2c"];
local nodeAz = "us-west-2b";

// List of namespaces where we have hubs deployed
// Each will get a ServiceAccount that will get credentials to talk
// to AWS services, via https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
local namespaces = ['staging', 'prod'];

// Node definitions for notebook nodes. Config here is merged
// with our notebook node definition.
// A `node.kubernetes.io/instance-type label is added, so pods
// can request a particular kind of node with a nodeSelector
local notebookNodes = [
    { instanceType: "m5.large", minNodes: 0 },
    { instanceType: "m5.xlarge", minNodes: 0 },
    { instanceType: "m5.2xlarge", minNodes: 0 },
    { instanceType: "m5.8xlarge", minNodes: 0 },
];

// Node definitions for dask worker nodes. Config here is merged
// with our dask worker node definition, which uses spot instances.
// A `node.kubernetes.io/instance-type label is set to the name of the
// *first* item in instanceDistribution.instanceTypes, to match
// what we do with notebook nodes. Pods can request a particular
// kind of node with a nodeSelector
local daskNodes = [
    { instancesDistribution+: { instanceTypes: ["m5.large"] }},
    { instancesDistribution+: { instanceTypes: ["m5.xlarge"] }},
    { instancesDistribution+: { instanceTypes: ["m5.2xlarge"] }},
    { instancesDistribution+: { instanceTypes: ["m5.8xlarge"] }},
];

{
    apiVersion: 'eksctl.io/v1alpha5',
    kind: 'ClusterConfig',
    metadata+: {
        name: "openscapeshub",
        region: clusterRegion,
        version: '1.21'
    },
    availabilityZones: masterAzs,
    iam: {
        withOIDC: true,

        serviceAccounts: [{
            metadata: {
                name: "cloud-user-sa",
                namespace: namespace
            },
            attachPolicyARNs:[
                "arn:aws:iam::aws:policy/AmazonS3FullAccess"
            ],
        } for namespace in namespaces],
    },
    nodeGroups: [n + {clusterName:: $.metadata.name} for n in [
        ng {
            name: 'core-b',
            availabilityZones: [nodeAz],
            ssh: {
                publicKeyPath: 'ssh-keys/openscapes.key.pub'
            },
            instanceType: "m5.xlarge",
            minSize: 1,
            maxSize: 6,
            labels+: {
                "hub.jupyter.org/node-purpose": "core",
                "k8s.dask.org/node-purpose": "core"
            },
            iam: {
                withAddonPolicies: {
                    autoScaler: true
                },
            },
        },
    ] + [
        ng {
            // NodeGroup names can't have a '.' in them, while
            // instanceTypes always have a .
            name: "nb-%s" % std.strReplace(n.instanceType, ".", "-"),
            availabilityZones: [nodeAz],
            minSize: n.minNodes,
            maxSize: 500,
            instanceType: n.instanceType,
            ssh: {
                publicKeyPath: 'ssh-keys/openscapes.key.pub'
            },
            labels+: {
                "hub.jupyter.org/node-purpose": "user",
                "k8s.dask.org/node-purpose": "scheduler"
            },
            taints+: {
                "hub.jupyter.org_dedicated": "user:NoSchedule",
                "hub.jupyter.org/dedicated": "user:NoSchedule"
            },

        } + n for n in notebookNodes
    ] + [
        ng {
            // NodeGroup names can't have a '.' in them, while
            // instanceTypes always have a .
            name: "dask-%s" % std.strReplace(n.instancesDistribution.instanceTypes[0], ".", "-"),
            availabilityZones: [nodeAz],
            minSize: 0,
            maxSize: 500,
            ssh: {
                publicKeyPath: 'ssh-keys/openscapes.key.pub'
            },
            labels+: {
                "k8s.dask.org/node-purpose": "worker"
            },
            taints+: {
                "k8s.dask.org_dedicated" : "worker:NoSchedule",
                "k8s.dask.org/dedicated" : "worker:NoSchedule"
            },
            instancesDistribution+: {
                onDemandBaseCapacity: 0,
                onDemandPercentageAboveBaseCapacity: 0,
                spotAllocationStrategy: "capacity-optimized",
            },
        } + n for n in daskNodes
    ]
    ]


}