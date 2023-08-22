#!/bin/sh
set -e
(
  cd "$(dirname "${0}")"

  # Types of outputs: https://plantuml.com/command-line#458de91d76a8569c
  java -jar plantuml.jar libertyEventDrivenSurvey-location.plantuml -utxt && \
    cat libertyEventDrivenSurvey-location.utxt && \
    java -jar plantuml.jar libertyEventDrivenSurvey-location.plantuml && \
    if [ "$(uname)" == "Darwin" ]; then
      open libertyEventDrivenSurvey-location.png
    fi
)
