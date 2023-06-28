# libertyEventDrivenSurvey

## Development

1. If using `podman machine`, set your connection to the `root` connection:
   ```
   podman system connection default podman-machine-default-root
   ```
1. Create Kafka container network if it doesn't exist:
   ```
   podman network create kafka
   ```
1. Start Kafka:
   ```
   podman run --rm -p 9092:9092 -e "ALLOW_PLAINTEXT_LISTENER=yes" -e "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-0:9092" --name kafka-0 --network kafka docker.io/bitnami/kafka
   ```
1. Build:
   ```
   mvn -Dimage.builder.arguments="--platform linux/amd64" -Dimage.checkpoint.arguments="--network kafka --user root" clean deploy
   ```

## Learn More

1. <https://developer.ibm.com/articles/develop-reactive-microservices-with-microprofile/>
1. <https://openliberty.io/guides/microprofile-reactive-messaging.html>
1. <https://smallrye.io/smallrye-reactive-messaging/latest/concepts/concepts/>
1. <https://openliberty.io/blog/2022/10/17/microprofile-serverless-ibm-code-engine.html>
1. <https://github.com/OpenLiberty/open-liberty/issues/19889>
1. <https://github.com/OpenLiberty/open-liberty/issues/21659>
