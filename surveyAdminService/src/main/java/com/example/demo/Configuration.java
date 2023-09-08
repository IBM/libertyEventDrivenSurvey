package com.example.demo;

public class Configuration {
	private static final String GOOGLE_API_KEY = System.getenv("GOOGLE_API_KEY");
	private static final String QRCODE_URL = System.getenv("QRCODE_URL");

	public static final int QRCODE_WIDTH = 512;
	public static final int QRCODE_HEIGHT = 512;
	
	// Default is Las Vegas, NV, US
	private static final double DEFAULT_SURVEY_LATITUDE = 36.10212330390405;
	private static final double DEFAULT_SURVEY_LONGITUDE = -115.174411774675;

	public static String getGoogleAPIKey() {
		return GOOGLE_API_KEY;
	}

	public static boolean isGoogleAPIKeyConfigured() {
		return GOOGLE_API_KEY != null && GOOGLE_API_KEY.length() > 0 && !GOOGLE_API_KEY.equals("INSERT_API_KEY");
	}

	public static String getQRCodeURL() {
		return QRCODE_URL != null && QRCODE_URL.length() > 0 ? QRCODE_URL : "https://ibm.com/";
	}
	
	public static double getSurveyLatitude() {
		double result = DEFAULT_SURVEY_LATITUDE;
		String latitude = System.getenv("SURVEY_LATITUDE");
		if (latitude != null && latitude.length() > 0) {
			result = Double.parseDouble(latitude);
		}
		return result;
	}
	
	public static double getSuveyLongitude() {
		double result = DEFAULT_SURVEY_LONGITUDE;
		String latitude = System.getenv("SURVEY_LONGITUDE");
		if (latitude != null && latitude.length() > 0) {
			result = Double.parseDouble(latitude);
		}
		return result;
	}
}
