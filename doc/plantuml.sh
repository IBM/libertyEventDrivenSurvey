#!/bin/sh
set -e
(
  cd "$(dirname "${0}")"
  java -jar plantuml.jar libertyEventDrivenSurvey-location.plantuml && \
    if [ "$(uname)" == "Darwin" ]; then
      open libertyEventDrivenSurvey-location.png
    fi
)
