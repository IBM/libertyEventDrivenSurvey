package com.example.demo.reactive;

import io.cloudevents.CloudEvent;
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

	@Path("locationInput")
	@POST
    @Produces(MediaType.APPLICATION_JSON)
	public Response cloudEvent1(CloudEvent incoming) {
		System.out.println("Received CloudEvent " + incoming);
		//Jsonb jsonb = JsonbBuilder.create();
		//CloudEventData data = incoming.getData();
		return Response.ok().build();
	}
}
