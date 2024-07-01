package com.example.demo.reactive;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.kafka.common.serialization.StringDeserializer;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import com.example.demo.Geocoder;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.maps.errors.ApiException;
import com.google.maps.model.PlaceDetails;

import io.cloudevents.CloudEvent;
import io.cloudevents.CloudEventData;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@RequestScoped
@Path("/cloudevents")
public class CloudEventsProcessor {
	private static final String CLASS_NAME = CloudEventsProcessor.class.getCanonicalName();
	private static final Logger LOG = Logger.getLogger(CLASS_NAME);
	private static final String ERROR_FAILED_GEOCODING = "Error performing geocoding";
	
	@Inject
	@Channel("geocodetopic")
	Emitter<String> emitter;

	@Path("locationInput")
	@POST
	@Produces(MediaType.APPLICATION_JSON)
	public Response locationInput(CloudEvent incoming) {
		if (LOG.isLoggable(Level.FINER))
			LOG.entering(CLASS_NAME, "locationInput", incoming);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Received CloudEvent: " + incoming);

		CloudEventData data = incoming.getData();

		if (LOG.isLoggable(Level.INFO))
			LOG.info("CloudEventData: " + data);

		String jsonString = null;
		try (StringDeserializer deserializer = new StringDeserializer()) {
			jsonString = deserializer.deserialize(null, data.toBytes());
		}

		JsonObject jsonObj = (new Gson()).fromJson(jsonString, JsonObject.class);
    String location = null;
    String color = null;
    String key = null;
    if(jsonObj.has("location")) {
      location = jsonObj.get("location").getAsString();
    } else {
      location = "unknown";
    }
    if(jsonObj.has("color")) {
      color = jsonObj.get("color").getAsString();
    } else {
      color = "grey";
    }
    if(jsonObj.has("key")) {
    	key = jsonObj.get("key").getAsString();
    } else {
    	key = "--";
    }

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Input location: " + location);

		Response result = null;

		try {
			PlaceDetails geocodeResult = Geocoder.geocode(location);

			if (LOG.isLoggable(Level.INFO))
				LOG.info("Geocode results: " + geocodeResult);

			double latitude = geocodeResult.geometry.location.lat;
			double longitude = geocodeResult.geometry.location.lng;

			if (LOG.isLoggable(Level.INFO))
				LOG.info("Geocoded point: " + latitude + "," + longitude);
			
			String jsonMessage = 
				"{" +
					"\"latitude\": "  + "\"" + latitude  + "\"," + 
					"\"longitude\": " + "\"" + longitude + "\"," + 
					"\"location\": "  + "\"" + location  + "\"," + 
					"\"color\": "     + "\"" + color     + "\","  + 
					"\"key\": "       + "\"" + key       + "\""  + 
				"}";

			emitter.send(jsonMessage);

			result = Response.ok().build();

		} catch (ApiException | InterruptedException | IOException e) {
			if (LOG.isLoggable(Level.SEVERE))
				LOG.log(Level.SEVERE, ERROR_FAILED_GEOCODING, e);

			result = Response.serverError().entity(ERROR_FAILED_GEOCODING + ": " + e.getMessage()).build();
		}

		if (LOG.isLoggable(Level.FINER))
			LOG.exiting(CLASS_NAME, "locationInput", result);

		return result;
	}
}
