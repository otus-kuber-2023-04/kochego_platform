local env = {
  name: std.extVar('qbec.io/env'),
  namespace: std.extVar('qbec.io/defaultNs'),
};
local p = import '../params.libsonnet';
local params = p.components.currencyservice;

[
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: params.name,
    },
    spec: {
      selector: {
        matchLabels: {
          app: params.name,
        },
      },
      template: {
        metadata: {
          labels: { app: params.name },
        },
        spec: {
          containers: [
            {
              name: 'server',
              image: params.image,
              ports: [
                {
                  name: params.servicePortName,
                  containerPort: params.containerPort,
                },
              ],
              env: [{name: "PORT", value: "7000"}],
              readinessProbe: {
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:7000",
                      ],
                  },
              },
              livenessProbe: {
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:7000",
                      ],
                  },
              },
                            resources: {requests: {cpu: "100m", memory: "64Mi"}, limits: {cpu: "200m", memory: "128Mi"}}
            },
          ],
        },
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: params.name,
    },
    spec: {
      selector: {
        app: params.name,
      },
      type: params.serviceType,
      ports: [
        {
          port: params.servicePort,
          name: params.servicePortName,
          targetPort: params.containerPort,
        },
      ],
    },
  },
  {
  },
]