# libertyEventDrivenSurvey

`libertyEventDrivenSurvey` is an example event-driven survey application demonstrating [Liberty InstantOn](https://openliberty.io/docs/latest/instanton.html), CloudEvents, KNative, and MicroProfile Reactive Messaging 3.

## Development

1. If using `podman machine`:
    1. Set your connection to the `root` connection:
       ```
       podman system connection default podman-machine-default-root
       ```
    1. If the machine has SELinux `virt_sandbox_use_netlink` disabled (i.e. the following returns `off`):
       ```
       podman machine ssh "getsebool virt_sandbox_use_netlink"
       ```
       Then, enable it:
       ```
       podman machine ssh "setsebool virt_sandbox_use_netlink 1"
       ```
       Note that this must be done after every time the podman machine restarts.
1. Build:
   ```
   mvn clean deploy
   ```

### Testing Locally

1. Create Kafka container network if it doesn't exist:
   ```
   podman network create kafka
   ```
1. Start Kafka:
   ```
   podman run --rm -p 9092:9092 -e "ALLOW_PLAINTEXT_LISTENER=yes" -e "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-0:9092" -e "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093" -e "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" -e "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka-0:9093" -e "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER" -e "KAFKA_CFG_PROCESS_ROLES=controller,broker" -e "KAFKA_CFG_NODE_ID=0" --name kafka-0 --network kafka docker.io/bitnami/kafka
   ```
1. Run `surveyInputService`:
   ```
   podman run --privileged --rm --network kafka  --rm -p 8080:8080 -p 8443:8443 -it localhost/surveyinputservice:latest
   ```
1. Wait for the message:
   ```
   [...] CWWKZ0001I: Application surveyInputService started [...]
   ```
1. Access <http://localhost:8080/location.html> or <https://localhost:8443/location.html>

### Additional Development Notes

#### Simple tests of the Geocoder Service

1. Run `surveyGeocoderService`:
   ```
   podman run --privileged --rm --rm -p 8080:8080 -p 8443:8443 -it localhost/surveygeocoderservice:latest
   ```
1. To post a [`CloudEvent`](https://github.com/cloudevents/spec/blob/v1.0/spec.md#required-attributes):
   ```
   curl -X POST http://localhost:8080/api/cloudevents/locationInput \
     -H "Ce-Source: https://example.com/" \
     -H "Ce-Id: $(uuidgen)" \
     -H "Ce-Specversion: 1.0" \
     -H "Ce-Type: CloudEvent1" \
     -H "Content-Type: application/json" \
     -d "\"Hello World\""
   ```

## Learn More

1. <https://developer.ibm.com/articles/develop-reactive-microservices-with-microprofile/>
1. <https://openliberty.io/guides/microprofile-reactive-messaging.html>
1. <https://smallrye.io/smallrye-reactive-messaging/latest/concepts/concepts/>
1. <https://openliberty.io/blog/2022/10/17/microprofile-serverless-ibm-code-engine.html>
1. <https://github.com/OpenLiberty/open-liberty/issues/19889>
1. <https://github.com/OpenLiberty/open-liberty/issues/21659>
