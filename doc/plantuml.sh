#!/bin/sh
set -e
(
  cd "$(dirname "${0}")"
  java -jar plantuml.jar libertyEventDrivenSurvey.plantuml && \
    if [ "$(uname)" == "Darwin" ]; then
      open libertyEventDrivenSurvey.png
    fi
)
