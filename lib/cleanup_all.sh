#!/bin/sh
kn source kafka delete geocodetopicsource
kn service delete surveyadminservice
kn source kafka delete locationtopicsource
kn service delete surveygeocoderservice
kn service delete surveyinputservice
echo "Waiting for pods to terminate..."
sleep 30
