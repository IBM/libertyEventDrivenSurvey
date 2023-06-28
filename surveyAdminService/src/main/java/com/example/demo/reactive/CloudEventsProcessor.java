package com.example.demo.reactive;

import io.cloudevents.CloudEvent;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@RequestScoped
@Path("/cloudevent")
public class CloudEventsProcessor {

	@Path("geocodeComplete")
	@POST
    @Produces(MediaType.APPLICATION_JSON)
	public Response cloudEvent1(CloudEvent incoming) {
		System.out.println("Received CloudEvent " + incoming);
		return Response.ok().build();
	}
}
