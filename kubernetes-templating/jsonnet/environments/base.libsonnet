{
  components: {
    currencyservice: {
      name: 'currencyservice',
      image: 'gcr.io/google-samples/microservices-demo/currencyservice:v0.1.3',
      containerPort: 7000,
      servicePortName: 'grpc',
      servicePort: 7000,
      app: 'currencyservice',
      serviceType: 'ClusterIP',
    },
  },
}