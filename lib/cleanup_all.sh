#!/bin/sh
set -e
kn source kafka delete geocodetopicsource && \
  kn service delete surveyadminservice && \
  kn source kafka delete locationtopicsource && \
  kn service delete surveygeocoderservice && \
  kn service delete surveyinputservice
