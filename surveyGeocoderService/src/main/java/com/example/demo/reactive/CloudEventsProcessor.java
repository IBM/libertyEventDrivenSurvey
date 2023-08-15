package com.example.demo.reactive;

import java.util.logging.Level;
import java.util.logging.Logger;

import io.cloudevents.CloudEvent;
import io.cloudevents.CloudEventData;
import jakarta.enterprise.context.RequestScoped;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
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

	@Path("locationInput")
	@POST
    @Produces(MediaType.APPLICATION_JSON)
	public Response locationInput(CloudEvent incoming) {
		if (LOG.isLoggable(Level.FINER))
			LOG.entering(CLASS_NAME, "locationInput", incoming);

		if (LOG.isLoggable(Level.INFO))
			LOG.info("Received CloudEvent: " + incoming);

		Jsonb jsonb = JsonbBuilder.create();
		CloudEventData data = incoming.getData();
		
		if (LOG.isLoggable(Level.INFO))
			LOG.info("CloudEventData: " + data);
		
		Response result = Response.ok().build();
		
		if (LOG.isLoggable(Level.FINER))
			LOG.exiting(CLASS_NAME, "locationInput", result);
		
		return result;
	}
}
