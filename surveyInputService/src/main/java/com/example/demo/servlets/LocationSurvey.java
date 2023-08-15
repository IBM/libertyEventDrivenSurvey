package com.example.demo.servlets;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("LocationSurvey")
public class LocationSurvey extends HttpServlet {
	private static final long serialVersionUID = 1L;

	private static final String CLASS_NAME = LocationSurvey.class.getCanonicalName();
	private static final Logger LOG = Logger.getLogger(CLASS_NAME);

	protected void service(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		if (LOG.isLoggable(Level.FINER))
			LOG.entering(CLASS_NAME, "service");

		String textInput1 = request.getParameter("textInput1");

		if (LOG.isLoggable(Level.INFO))
			LOG.info("textInput1: " + textInput1);

		if (textInput1 != null && textInput1.length() > 0) {
			
			// Input is good! Publish to Kafka
			
			writeResponse(response, """
					        <h1>Thank you!</h1>
					        <p>Your submission has been received. You may close this window.</p>
					""");
		} else {
			writeResponse(response, """
					        <h1>Error</h1>
					        <p>Please enter a location.</p>
					""");
		}

		if (LOG.isLoggable(Level.FINER))
			LOG.exiting(CLASS_NAME, "service");
	}

	private void writeResponse(HttpServletResponse response, String message) throws IOException {
		response.setContentType("text/html");
		response.getWriter().println("""
				<!DOCTYPE html>
				<html>
				  <head>
				    <title>Location Survey</title>
				    <meta charset="UTF-8">
				    <meta name="viewport" content="width=device-width, initial-scale=1.0">
				    <style>
				      html, body, .container {
				        height: 100%;
				      }

				      .container {
				        display: flex;
				        align-items: center;
				        justify-content: center;
				      }
				    </style>
				  </head>
				  <body>
					<div class="container">
						<div>
				""" + message + """
						</div>
					</div>
				  </body>
				</html>
				""");
	}
}
