# libertyEventDrivenSurvey

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
1. Create Kafka container network if it doesn't exist:
   ```
   podman network create kafka
   ```
1. Start Kafka:
   ```
   podman run --rm -p 9092:9092 -e "ALLOW_PLAINTEXT_LISTENER=yes" -e "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-0:9092" -e "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093" -e "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" -e "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka-0:9093" -e "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER" -e "KAFKA_CFG_PROCESS_ROLES=controller,broker" -e "KAFKA_CFG_NODE_ID=0" --name kafka-0 --network kafka docker.io/bitnami/kafka
   ```
1. Build:
   ```
   mvn clean deploy
   ```
1. Run the `surveyInputService`:
   ```
   podman run --privileged --rm --network kafka  --rm -p 9080:9080 -p 9443:9443 -it localhost/surveyinputservice:latest
   ```
1. Wait for the message:
   ```
   [...] CWWKZ0001I: Application surveyInputService started [...]
   ```
1. Access <http://localhost:9080/location.html> or <https://localhost:9443/location.html>

## Learn More

1. <https://developer.ibm.com/articles/develop-reactive-microservices-with-microprofile/>
1. <https://openliberty.io/guides/microprofile-reactive-messaging.html>
1. <https://smallrye.io/smallrye-reactive-messaging/latest/concepts/concepts/>
1. <https://openliberty.io/blog/2022/10/17/microprofile-serverless-ibm-code-engine.html>
1. <https://github.com/OpenLiberty/open-liberty/issues/19889>
1. <https://github.com/OpenLiberty/open-liberty/issues/21659>
