# libertyEventDrivenSurvey

`libertyEventDrivenSurvey` is an example event-driven survey application demonstrating [Liberty InstantOn](https://openliberty.io/docs/latest/instanton.html), CloudEvents, KNative, and MicroProfile Reactive Messaging 3.

The way it works is that users scan a QR code presented by the person running the survey and users type in a location (e.g. New York). This is submitted to a microservice that can scale from zero using KNative Serving and quickly using Liberty InstantOn. This web service publishes the location to a Kafka topic. Another microservice that can scale from zero using KNative Eventing and the KNative Kafka Broker and quickly using Liberty InstantOn then receives this event and geocodes the location to a latitude and longitude through a Geoapify or Google Maps API. Finally, this pin works its way back through another Kafka topic and WebSockets back to the map that the person running the survey is showing.

## Screeenshots and Architecture for Geocoding

![Screenshot](lib/screenshot.png)

![Spinner](lib/spinner.gif)

![Architecture diagram](lib/libertyEventDrivenSurvey-location.png)

## Deploy to OpenShift >= 4.13

### Pre-requisities

1. Create project `amq-streams-kafka`
1. Install Kafka; for example, the [Red Hat `Streams for Apache Kafka` operator](https://access.redhat.com/documentation/en-us/red_hat_streams_for_apache_kafka/2.7/html/getting_started_with_streams_for_apache_kafka_on_openshift/proc-deploying-cluster-operator-hub-str)
    1. OperatorHub } AMQ Streams } A specific namespace = `amq-streams-kafka`
    1. Kafka } Create Instance } my-cluster } Use all default options } Create
    1. Wait for `Condition: Ready`
        1. If you get a warning about "inter.broker.protocol.version", apply the [known workaround](https://access.redhat.com/solutions/7020156)
    1. Kafka Topic } Create KafkaTopic } `locationtopic` } Create
    1. Kafka Topic } Create KafkaTopic } `geocodetopic` } Create
1. Install KNative; for example, the [Red Hat `OpenShift Serverless` operator](https://docs.openshift.com/serverless/1.29/install/install-serverless-operator.html)
    1. Install the [`kn` command line utility](https://docs.openshift.com/serverless/1.29/install/installing-kn.html)
        1. Alternatively, install the latest version of [kn](https://knative.dev/docs/client/install-kn/#verifying-cli-binaries) and the [kafka plugin](https://knative.dev/docs/client/kn-plugins/#list-of-knative-plugins)
            1. macOS:
               ```
               brew install knative/client/kn knative-sandbox/kn-plugins/source-kafka
               ```
    1. Install [KNative Serving](https://docs.openshift.com/serverless/1.29/install/installing-knative-serving.html)
        1. Operators } Installed Operators
        1. Project = `knative-serving`
        1. Red Hat OpenShift Serverless } Knative Serving
        1. Create KnativeServing
        1. Click `Create`
        1. Wait for the `Ready` Condition in `Status`
    1. Install [KNative Eventing](https://docs.openshift.com/serverless/1.29/install/installing-knative-eventing.html)
        1. Operators } Installed Operators
        1. Project = `knative-eventing`
        1. Red Hat OpenShift Serverless } Knative Eventing
        1. Create KnativeEventing
        1. Click `Create`
        1. Wait for the `Ready` Condition in `Status`
    1. Install the [`KNativeKafka` broker](https://docs.openshift.com/serverless/1.29/install/installing-knative-eventing.html#serverless-install-kafka-odc_installing-knative-eventing)
        1. Knative Kafka } Create KnativeKafka
        1. channel } enabled; bootstrapServers } my-cluster-kafka-bootstrap.amq-streams-kafka.svc:9092
        1. source } enabled
        1. broker } enabled; defaultConfig } bootstrapServers } my-cluster-kafka-bootstrap.amq-streams-kafka.svc:9092
        1. sink } enabled
        1. Click `Create`
        1. Wait for the `Ready` Condition in `Status`
1. Change directory to this cloned repository
1. Create and switch to some test project:
   ```
   oc new-project libertysurvey
   ```
1. Choose your geocoding provider:
    1. Get a [Geoapify key](https://www.geoapify.com/pricing/) (default)
        1. [Free commercial usage](https://www.geoapify.com/):
           > When you stay within the Free pricing plan quota, you can use the Maps API for free, even for a commercial app.
        1. [Attribution policy](https://www.geoapify.com/terms-and-conditions/)
           > Geoapify attribution is mandatory when using Free subscription plan.
    1. Or get a [Google Maps API key](https://developers.google.com/maps/documentation/javascript/get-api-key) (simple usage should fit [within the free tier](https://mapsplatform.google.com/pricing/))
        1. In general, it's recommended to use a restricted API key in case it is stolen. If you would like to do this, note that the same API key is used both by the JavaScript frontend in the browser and one of the services running in Kubernetes, so both would need to be allowed (e.g. by IP, etc.).
        1. After creating the API key, go to [Enabled APIs & services](https://console.cloud.google.com/apis/dashboard), click `ENABLE APIS AND SERVICES`, and make sure that `Maps JavaScript API` and `Places API` are enabled.
1. Create a service account for InstantOn:
   ```
   oc create serviceaccount instanton-sa
   ```
1. Create an InstantOn SecurityContextConstraints:
   ```
   oc apply -f lib/instantonscc.yaml
   ```
1. Associate the InstantOn SecurityContextConstraints with the service account:
   ```
   oc adm policy add-scc-to-user cap-cr-scc -z instanton-sa
   ```
1. To use InstantOn, we need to modify KNative Serving configuration which [must be done](https://knative.dev/docs/install/operator/configuring-with-operator/) through the operator:
    1. Operators } Installed Operators
    1. Project = `knative-serving`
    1. Red Hat OpenShift Serverless } Knative Serving
    1. Click `knative-serving`
    1. Click `YAML`
    1. Under `spec`, add:
       ```
         config:
           features:
             kubernetes.containerspec-addcapabilities: enabled
             kubernetes.podspec-securitycontext: enabled
       ```
    1. Click `Save`

#### Kafka Security

If you want to enable Kafka Security (e.g. SASL), then you will need to follow the relevant steps in [Kafka connector security configuration](https://openliberty.io/docs/latest/liberty-kafka-connector-config-security.html) and change the relevant YAML configurations below. This may involve, for example, adding a keystore to some of the containers (either during the build phase or by mounting a directory).

### Deploy surveyInputService

1. Copy `lib/example_surveyinputservice.yaml.template` into `lib/example_surveyinputservice.yaml`, and then:
    1. If needed, replace `mp.messaging.connector.liberty-kafka.bootstrap.servers` with the AMQ Streams Kafka Cluster bootstrap address
    1. If using a local build, replace `image` with `image-registry.openshift-image-registry.svc:5000/libertysurvey/surveyinputservice`
    1. Run:
       ```
       oc apply -f lib/example_surveyinputservice.yaml
       ```
1. Query until `READY` is `True`:
   ```
   kn service list surveyinputservice
   ```
1. Open your browser to the URL from the `kn service list` output above and click on `Location Survey`.
1. Double check logs look good:
   ```
   oc exec -it $(oc get pod -o name | grep surveyinputservice) -c surveyinputservice -- cat /logs/messages.log
   ```
1. Note that `scale-down-delay` does not apply to the initial pod creation so the pod will be terminated about 30 seconds after it's initially created. Once a real user request is made to this application, then `scale-down-delay` will apply. Therefore, if you want to tail the logs of the pod, first wait for the initial pod to terminate and then make a request to the application and then you can tail the pod logs.

### Deploy surveyAdminService

1. Copy `lib/example_surveyadminservice.yaml.template` into `lib/example_surveyadminservice.yaml`, and then:
    1. If using Google as the map provider, add a `GOOGLE_API_KEY` `env` entry with your Google Maps API key
    1. Replace `INSERT_URL` with the URL from the `serviceInputService` above appended with `location.html`
    1. If needed, replace `SURVEY_LATITUDE` and `SURVEY_LONGITUDE` (defaults to Las Vegas, NV, USA)
    1. If needed, replace `mp.messaging.connector.liberty-kafka.bootstrap.servers` with the AMQ Streams Kafka Cluster bootstrap address
    1. If using a local build, replace `image` with `image-registry.openshift-image-registry.svc:5000/libertysurvey/surveyadminservice`
    1. Run:
       ```
       oc apply -f lib/example_surveyadminservice.yaml
       ```
1. Query until `READY` is `True`:
   ```
   kn service list surveyadminservice
   ```
1. Open your browser to the URL from the `kn service list` output above and click on `Start New Geolocation Survey`.
1. Double check logs look good:
   ```
   oc exec -it $(oc get pod -o name | grep surveyadminservice) -c surveyadminservice -- cat /logs/messages.log
   ```
1. Create a KNative Eventing KafkaSource for `surveyAdminService` (if needed, replace `bootstrapServers` with the AMQ Streams Kafka Cluster bootstrap address):
   ```
   oc apply -f lib/example_surveyadminkafkasource.yaml
   ```
1. Query until `OK` is `++` for all lines:
   ```
   kn source kafka describe geocodetopicsource
   ```
1. Note that `scale-down-delay` does not apply to the initial pod creation so the pod will be terminated about 30 seconds after it's initially created. Once a real user request is made to this application, then `scale-down-delay` will apply. Therefore, if you want to tail the logs of the pod, first wait for the initial pod to terminate and then make a request to the application and then you can tail the pod logs.

### Deploy surveyGeocoderService

1. Copy `lib/example_surveygeocoderservice.yaml.template` into `lib/example_surveygeocoderservice.yaml`, and then:
    1. If using Geoapify as the geocoding provider (default), add a `GEOAPIFY_API_KEY` `env` entry with your Geoapify API key
    1. If using Google as the geocoding provider, add a `GOOGLE_API_KEY` `env` entry with your Google Maps API key
    1. If needed, replace `mp.messaging.connector.liberty-kafka.bootstrap.servers` with the AMQ Streams Kafka Cluster bootstrap address
    1. If using a local build, replace `image` with `image-registry.openshift-image-registry.svc:5000/libertysurvey/surveygeocoderservice`
    1. Run:
       ```
       oc apply -f lib/example_surveygeocoderservice.yaml
       ```
1. Query until `READY` is `True`:
   ```
   kn service list surveygeocoderservice
   ```
1. Double check logs look good:
   ```
   oc exec -it $(oc get pod -o name | grep surveygeocoderservice) -c surveygeocoderservice -- cat /logs/messages.log
   ```
1. Create a KNative Eventing KafkaSource for `surveyGeocoderService` (if needed, replace `bootstrapServers` with the AMQ Streams Kafka Cluster bootstrap address):
   ```
   oc apply -f lib/example_surveygeocoderkafkasource.yaml
   ```
1. Query until `OK` is `++` for all lines:
   ```
   kn source kafka describe locationtopicsource
   ```
1. Note that `scale-down-delay` does not apply to the initial pod creation so the pod will be terminated about 30 seconds after it's initially created. Once a real user request is made to this application, then `scale-down-delay` will apply. Therefore, if you want to tail the logs of the pod, first wait for the initial pod to terminate and then make a request to the application and then you can tail the pod logs.

### Testing Deployment

1. Open the `surveyadminservice` `geolocation.jsp` page in one browser tab.
1. Open the `surveyinputservice` `location.html` page in another browser tab, enter a location, and click Submit.
1. Switch back to the `surveyadminservice` and wait for the pin to be added.

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
       podman machine ssh "sudo setsebool virt_sandbox_use_netlink 1"
       ```
       Note that this must be done after every time the podman machine restarts.
1. Build:
   ```
   mvn clean deploy
   ```
1. Ensure the [internal OpenShift registry is available](https://docs.openshift.com/container-platform/latest/registry/securing-exposing-registry.html):
   ```
   oc patch configs.imageregistry.operator.openshift.io/cluster --patch "{\"spec\":{\"defaultRoute\":true}}" --type=merge
   ```
1. Push `surveyInputService` to the registry:
   ```
   REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
   echo "Registry host: ${REGISTRY}"
   printf "Does it look good (yes=ENTER, no=Ctrl^C)? "
   read trash
   podman login --tls-verify=false -u $(oc whoami | sed 's/://g') -p $(oc whoami -t) ${REGISTRY}
   podman tag localhost/surveyinputservice $REGISTRY/libertysurvey/surveyinputservice
   podman push --tls-verify=false $REGISTRY/libertysurvey/surveyinputservice
   ```
1. Push `surveyAdminService` to the registry:
   ```
   REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
   echo "Registry host: ${REGISTRY}"
   printf "Does it look good (yes=ENTER, no=Ctrl^C)? "
   read trash
   podman login --tls-verify=false -u $(oc whoami | sed 's/://g') -p $(oc whoami -t) ${REGISTRY}
   podman tag localhost/surveyadminservice $REGISTRY/libertysurvey/surveyadminservice
   podman push --tls-verify=false $REGISTRY/libertysurvey/surveyadminservice
   ```
1. Push `surveyGeocoderService` to the registry:
   ```
   REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
   echo "Registry host: ${REGISTRY}"
   printf "Does it look good (yes=ENTER, no=Ctrl^C)? "
   read trash
   podman login --tls-verify=false -u $(oc whoami | sed 's/://g') -p $(oc whoami -t) ${REGISTRY}
   podman tag localhost/surveygeocoderservice $REGISTRY/libertysurvey/surveygeocoderservice
   podman push --tls-verify=false $REGISTRY/libertysurvey/surveygeocoderservice
   ```

## Update KNative Service to new image

Run `kn service update` with the service name and the same image name from the YAML; for examples:

```
kn service update surveyinputservice --image=image-registry.openshift-image-registry.svc:5000/libertysurvey/surveyinputservice

kn service update surveygeocoderservice --image=image-registry.openshift-image-registry.svc:5000/libertysurvey/surveygeocoderservice

kn service update surveyadminservice --image=image-registry.openshift-image-registry.svc:5000/libertysurvey/surveyadminservice
```

## Test

1. Submit a location input:
    1. Using the command line:
        1. Execute:
           ```
           curl -k --data "textInput1=New York, NY" "$(kn service list surveyinputservice -o jsonpath="{.items[0].status.url}{'\n'}")/LocationSurvey"
           ```
        1. Check for a successful output:
           ```
           Your submission has been received
           ```
    1. Using the browser:
        1. Find and open the URL:
           ```
           kn service list surveyinputservice -o jsonpath="{.items[0].status.url}{'/location.html\n'}"
           ```
        1. Click `Location Survey` and submit the form
1. Double check logs look good:
   ```
   oc exec -it $(oc get pod -o name | grep surveygeocoderservice) -c surveygeocoderservice -- tail -f /logs/messages.log
   ```

## Debugging

1. Tail `surveyinputservice` logs:
   ```
   oc exec -it $(oc get pod -o name | grep surveyinputservice) -c surveyinputservice -- tail -f /logs/messages.log
   ```
1. Tail `surveyadminservice` logs:
   ```
   oc exec -it $(oc get pod -o name | grep surveyadminservice) -c surveyadminservice -- tail -f /logs/messages.log
   ```
1. Tail `surveygeocoderservice` logs:
   ```
   oc exec -it $(oc get pod -o name | grep surveygeocoderservice) -c surveygeocoderservice -- tail -f /logs/messages.log
   ```

## Clean-up tasks

```
lib/cleanup_all.sh
```

### Delete surveyAdminService

1. Delete the KafkaSource:
   ```
   kn source kafka delete geocodetopicsource
   ```
1. Delete the KNative Service:
   ```
   kn service delete surveyadminservice
   ```

### Delete surveyGeocoderService

1. Delete the KafkaSource:
   ```
   kn source kafka delete locationtopicsource
   ```
1. Delete the KNative Service:
   ```
   kn service delete surveygeocoderservice
   ```

### Delete surveyInputService

```
kn service delete surveyinputservice
```

## Testing Locally

Only some functions can be tested locally without KNative.

### Testing surveyAdminService

1. Run `surveyAdminService`:
   ```
   podman run --privileged --rm -e GEOAPIFY_API_KEY=YOUR_KEY -p 8080:8080 -p 8443:8443 -it localhost/surveyadminservice:latest
   ```
1. Open browser to <http://localhost:8080/geolocation.jsp>
1. Post a [`CloudEvent`](https://github.com/cloudevents/spec/blob/v1.0/spec.md#required-attributes):
   ```
   curl -X POST http://localhost:8080/api/cloudevents/geocodeComplete \
     -H "Ce-Source: https://example.com/" \
     -H "Ce-Id: $(uuidgen)" \
     -H "Ce-Specversion: 1.0" \
     -H "Ce-Type: CloudEvent1" \
     -H "Content-Type: text/plain" \
     -d "40.7127753 -74.0059728 New York, NY"
   ```
1. Switch back to the browser and you should see the point.

### Testing surveyInputService

1. Create Kafka container network if it doesn't exist:
   ```
   podman network create kafka
   ```
1. Start Kafka if it's not started:
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

### Testing surveyGeocoderService

1. Create Kafka container network if it doesn't exist:
   ```
   podman network create kafka
   ```
1. Start Kafka if it's not started:
   ```
   podman run --rm -p 9092:9092 -e "ALLOW_PLAINTEXT_LISTENER=yes" -e "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-0:9092" -e "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093" -e "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" -e "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka-0:9093" -e "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER" -e "KAFKA_CFG_PROCESS_ROLES=controller,broker" -e "KAFKA_CFG_NODE_ID=0" --name kafka-0 --network kafka docker.io/bitnami/kafka
   ```
1. Run `surveyGeocoderService`:
   ```
   podman run --privileged --rm -p 8080:8080 -p 8443:8443 -e "GEOAPIFY_API_KEY=INSERT_API_KEY" -it localhost/surveygeocoderservice:latest
   ```
1. Post a [`CloudEvent`](https://github.com/cloudevents/spec/blob/v1.0/spec.md#required-attributes):
   ```
   curl -X POST http://localhost:8080/api/cloudevents/locationInput \
     -H "Ce-Source: https://example.com/" \
     -H "Ce-Id: $(uuidgen)" \
     -H "Ce-Specversion: 1.0" \
     -H "Ce-Type: CloudEvent1" \
     -H "Content-Type: text/plain" \
     -d "New York, NY"
   ```

### Testing without containers

1. Change directory to the application
1. `GEOAPIFY_API_KEY=INSERT_API_KEY mvn clean liberty:dev`
1. Open <http://localhost:8080/>

## Steps to publish new images to Quay

1. Set a variable to this version in your shell; for example:
   ```
   VERSION="240012"
   ```
1. List local images:
   ```
   podman images
   REPOSITORY                        TAG       IMAGE ID      CREATED         SIZE
   localhost/surveygeocoderservice   latest    4fb2fc7d5a7c  19 seconds ago  1.52 GB
   localhost/surveyinputservice      latest    92ee9560daa7  3 minutes ago   1.49 GB
   localhost/surveyadminservice      latest    449a71e98b45  5 minutes ago   1.52 GB
   ```
1. Tag the images for Quay:
   ```
   podman tag localhost/surveygeocoderservice quay.io/ibm/libertyeventdrivensurvey:surveygeocoderservice${VERSION}
   podman tag localhost/surveyinputservice quay.io/ibm/libertyeventdrivensurvey:surveyinputservice${VERSION}
   podman tag localhost/surveyadminservice quay.io/ibm/libertyeventdrivensurvey:surveyadminservice${VERSION}
   ```
1. Log into Quay:
   ```
   podman login quay.io
   ```
1. Push with the version in step 1:
   ```
   podman push quay.io/ibm/libertyeventdrivensurvey:surveygeocoderservice${VERSION}
   podman push quay.io/ibm/libertyeventdrivensurvey:surveyinputservice${VERSION}
   podman push quay.io/ibm/libertyeventdrivensurvey:surveyadminservice${VERSION}
   ```

## Learn More

1. <https://developer.ibm.com/articles/develop-reactive-microservices-with-microprofile/>
1. <https://openliberty.io/guides/microprofile-reactive-messaging.html>
1. <https://smallrye.io/smallrye-reactive-messaging/latest/concepts/concepts/>
1. <https://openliberty.io/blog/2022/10/17/microprofile-serverless-ibm-code-engine.html>
1. <https://github.com/OpenLiberty/open-liberty/issues/19889>
1. <https://github.com/OpenLiberty/open-liberty/issues/21659>
