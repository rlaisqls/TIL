<img height="398" alt="image" src="https://github.com/user-attachments/assets/7986456e-9dcb-45bf-8165-e738fe2c0b12" />

Argo Events is an event-driven workflow automation framework for Kubernetes which helps you trigger K8s objects, Argo Workflows, Serverless workloads, etc. on events from a variety of sources like webhooks, S3, schedules, messaging queues, gcp pubsub, sns, sqs, etc.

### Event Source

- An EventSource defines the configurations required to consume events from external sources like AWS SNS, SQS, GCP PubSub, Webhooks, etc. It further transforms the events into the [cloudevents](https://github.com/cloudevents/spec) and dispatches them over to the eventbus.
  - Multiple events can be configured in a single EventSource, they can be either one event source type, or mixed event source types with some limitations.

- <https://argoproj.github.io/argo-events/APIs/#argoproj.io/v1alpha1.EventSourceSpec>
- <https://github.com/argoproj/argo-events/tree/master/examples/event-sources>

### Sensor

- Sensor defines a set of event dependencies (inputs) and triggers (outputs). It listens to events on the eventbus and acts as an event dependency manager to resolve and execute the triggers.
Event dependency
- A dependency is an event the sensor is waiting to happen.
- Sensor controller creates a k8s deployment (replica number defaults to 1) for each Sensor object. HA with Active-Passive strategy can be achieved by setting spec.replicas to a number greater than 1, which means only one Pod serves traffic and the rest ones stand by. One of standby Pods will be automatically elected to be active if the old one is gone.
  - Manually scaling up the replicas might cause unexpected behavior
  - By default, Argo Events will use NATS for the HA leader election except when using a Kafka Eventbus, in which case a leader election is not required as a Sensor that uses a Kafka EventBus is capable of horizontally scaling. If using a different EventBus you can opt-in to a Kubernetes native leader election by specifying the following annotation.

    ```
    annotations:
    events.argoproj.io/leader-election: k8s
    ```

  - <https://argoproj.github.io/argo-events/dr_ha_recommendations/>

Kubernetes Leader Election

- <https://argoproj.github.io/argo-events/APIs/#argoproj.io/v1alpha1.Sensor>
- <https://github.com/argoproj/argo-events/tree/master/examples/sensors>

### EventBus

- The EventBus acts as the transport layer of Argo-Events by connecting the EventSources and Sensors.
- EventSources publish the events while the Sensors subscribe to the events to execute triggers.
- There are three implementations of the EventBus: NATS (deprecated), [Jetstream](https://docs.nats.io/nats-concepts/jetstream), and [Kafka](https://kafka.apache.org).
