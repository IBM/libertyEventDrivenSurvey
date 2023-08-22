package com.example.demo;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.maps.GeoApiContext;
import com.google.maps.PlaceAutocompleteRequest.SessionToken;
import com.google.maps.PlaceDetailsRequest.FieldMask;
import com.google.maps.PlacesApi;
import com.google.maps.errors.ApiException;
import com.google.maps.model.AutocompletePrediction;
import com.google.maps.model.PlaceAutocompleteType;
import com.google.maps.model.PlaceDetails;

public class Geocoder {
	private static final String CLASS_NAME = Geocoder.class.getCanonicalName();
	private static final Logger LOG = Logger.getLogger(CLASS_NAME);

	static GeoApiContext context;

	static {
		String apiKey = System.getenv("GOOGLE_API_KEY");

		if (LOG.isLoggable(Level.FINEST))
			LOG.finest("GOOGLE_API_KEY: " + apiKey);

		if (apiKey == null || "INSERT_API_KEY".equals(apiKey))
			throw new RuntimeException("GOOGLE_API_KEY environment variable value is invalid: " + apiKey);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Loading Google Maps API context");

		context = new GeoApiContext.Builder().apiKey(apiKey).build();

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Successfully loaded Google Maps API context");
	}

	public static PlaceDetails geocode(String location) throws ApiException, InterruptedException, IOException {
		if (LOG.isLoggable(Level.FINER))
			LOG.entering(CLASS_NAME, "geocode", location);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("geocode: " + location);

		SessionToken session = new SessionToken();

		// https://developers.google.com/maps/documentation/places/web-service/autocomplete
		// https://www.javadoc.io/doc/com.google.maps/google-maps-services/latest/index.html
		// https://www.javadoc.io/doc/com.google.maps/google-maps-services/latest/com/google/maps/PlacesApi.html
		AutocompletePrediction[] predictions = PlacesApi.placeAutocomplete(context, location, session)
				.types(PlaceAutocompleteType.CITIES).types(PlaceAutocompleteType.REGIONS).await();

		if (LOG.isLoggable(Level.INFO)) {
			Gson gson = new GsonBuilder().setPrettyPrinting().create();
			LOG.info("Predictions: " + gson.toJson(predictions));
		}

		if (predictions == null || predictions.length == 0) {
			throw new RuntimeException("No predictions found");
		}

		// https://developers.google.com/maps/documentation/places/web-service/details
		PlaceDetails result = PlacesApi.placeDetails(context, predictions[0].placeId, session)
				.fields(FieldMask.GEOMETRY_LOCATION).await();

		if (LOG.isLoggable(Level.INFO)) {
			Gson gson = new GsonBuilder().setPrettyPrinting().create();
			LOG.info("First place details: " + gson.toJson(result));
		}

		if (LOG.isLoggable(Level.FINER))
			LOG.exiting(CLASS_NAME, "geocode", result);

		return result;
	}
}
