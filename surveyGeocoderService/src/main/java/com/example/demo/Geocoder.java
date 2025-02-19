package com.example.demo;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import com.google.maps.GeoApiContext;
import com.google.maps.PlaceAutocompleteRequest.SessionToken;
import com.google.maps.PlaceDetailsRequest.FieldMask;
import com.google.maps.PlacesApi;
import com.google.maps.errors.ApiException;
import com.google.maps.model.AutocompletePrediction;
import com.google.maps.model.PlaceAutocompleteType;
import com.google.maps.model.PlaceDetails;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import org.json.JSONObject;
import org.json.JSONArray;

public class Geocoder {
	private static final String CLASS_NAME = Geocoder.class.getCanonicalName();
	private static final Logger LOG = Logger.getLogger(CLASS_NAME);

	static GeoApiContext context;
	static String geoapifyKey;

	static {
		if (LOG.isLoggable(Level.INFO))
			LOG.info("Started static loading of Geocoder class");

		String googleApiKey = System.getenv("GOOGLE_API_KEY");

		if (LOG.isLoggable(Level.FINEST))
			LOG.finest("GOOGLE_API_KEY: " + googleApiKey);

		if (Configuration.isMapTypeGoogle() && (googleApiKey == null || "INSERT_API_KEY".equals(googleApiKey)))
			throw new RuntimeException("GOOGLE_API_KEY environment variable value is missing or invalid: " + googleApiKey);

		context = Configuration.isMapTypeGoogle() ? new GeoApiContext.Builder().apiKey(googleApiKey).build() : null;

		geoapifyKey = System.getenv("GEOAPIFY_API_KEY");

		if (LOG.isLoggable(Level.FINEST))
			LOG.finest("GEOAPIFY_API_KEY: " + geoapifyKey);

		if (Configuration.isMapTypeOSM() && (geoapifyKey == null || "INSERT_API_KEY".equals(geoapifyKey)))
			throw new RuntimeException("GEOAPIFY_API_KEY environment variable value is missing or invalid: " + geoapifyKey);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Successfully loaded Geocoder class");
	}

	public static class GeocodeResults {
		public double latitude;
		public double longitude;
	}

	public static GeocodeResults geocode(String location) throws ApiException, InterruptedException, IOException {
		if (LOG.isLoggable(Level.FINER))
			LOG.entering(CLASS_NAME, "geocode", location);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("geocode with " + Configuration.MAP_TYPE + ": " + location);

		GeocodeResults finalResult = new GeocodeResults();

		if (Configuration.isMapTypeOSM()) {
			// https://apidocs.geoapify.com/playground/geocoding/?params=%7B%22query%22:%22New%20York,%20NY%22,%22filterValue%22:%7B%22radiusMeters%22:1000%7D,%22biasValue%22:%7B%22radiusMeters%22:1000%7D%7D&geocodingSearchType=full
			OkHttpClient client = new OkHttpClient();
			Request request = new Request.Builder()
        .url("https://api.geoapify.com/v1/geocode/search?text=" + URLEncoder.encode(location, StandardCharsets.UTF_8.name()) + "&format=json&apiKey=" + geoapifyKey)
        .build();

			try (Response response = client.newCall(request).execute()) {
				String json = response.body().string();

				if (LOG.isLoggable(Level.INFO))
					LOG.info("geoapify: " + json);

				// https://stleary.github.io/JSON-java/org/json/JSONObject.html
				JSONObject obj = new JSONObject(json);
				JSONArray results = obj.getJSONArray("results");
				if (results.length() > 0) {
					JSONObject loc = results.getJSONObject(0);
					finalResult.latitude = loc.getDouble("lat");
					finalResult.longitude = loc.getDouble("lon");
				} else {
					throw new RuntimeException("No geoapify results for " + location);
				}
			}
		} else if (Configuration.isMapTypeGoogle()) {
			SessionToken session = new SessionToken();

			// https://developers.google.com/maps/documentation/places/web-service/autocomplete
			// https://www.javadoc.io/doc/com.google.maps/google-maps-services/latest/index.html
			// https://www.javadoc.io/doc/com.google.maps/google-maps-services/latest/com/google/maps/PlacesApi.html
			AutocompletePrediction[] predictions = PlacesApi.placeAutocomplete(context, location, session)
					.types(PlaceAutocompleteType.CITIES).types(PlaceAutocompleteType.REGIONS).await();

			/*-
			* TODO:
			* We can't serialize the results to a String using Gson because of the following error.
			* This is only for debug anyway, so not a big deal.
			* 
			* Caused by: java.lang.reflect.InaccessibleObjectException: Unable to make field private final byte java.time.LocalTime.hour accessible: module java.base does not "opens java.time" to unnamed module @73fd66b
			* [...]
			* 	at com.google.gson.internal.reflect.ReflectionHelper.makeAccessible(ReflectionHelper.java:35)

			if (LOG.isLoggable(Level.INFO)) {
				Gson gson = new GsonBuilder().setPrettyPrinting().create();
				LOG.info("Predictions: " + gson.toJson(predictions));
			}
			*/

			if (predictions == null || predictions.length == 0) {
				throw new RuntimeException("No predictions found for " + location);
			}

			// https://developers.google.com/maps/documentation/places/web-service/details
			PlaceDetails result = PlacesApi.placeDetails(context, predictions[0].placeId, session)
					.fields(FieldMask.GEOMETRY_LOCATION).await();

			if (LOG.isLoggable(Level.FINER))
				LOG.exiting(CLASS_NAME, "geocode", result);

			finalResult.latitude = result.geometry.location.lat;
			finalResult.longitude = result.geometry.location.lng;
		} else {
			throw new RuntimeException("Unknown map type " + Configuration.MAP_TYPE);
		}
		return finalResult;
	}
}
