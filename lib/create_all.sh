#!/bin/sh
set -e
oc apply -f lib/example_surveyinputservice.yaml && \
  sleep 30 && \
  kn service list surveyinputservice && \
  oc apply -f lib/example_surveyadminservice.yaml && \
  sleep 30 && \
  kn service list surveyadminservice && \
  oc apply -f lib/example_surveyadminkafkasource.yaml && \
  sleep 30 && \
  kn source kafka describe geocodetopicsource && \
  oc apply -f lib/example_surveygeocoderservice.yaml && \
  sleep 30 && \
  kn service list surveygeocoderservice && \
  oc apply -f lib/example_surveygeocoderkafkasource.yaml && \
  sleep 30 && \
  kn source kafka describe locationtopicsource && \
  sleep 60
