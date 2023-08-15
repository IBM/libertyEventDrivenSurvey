package com.example.demo;

import java.util.HashSet;
import java.util.Set;

import com.example.demo.reactive.CloudEventsProcessor;

import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;

@ApplicationPath("api")
public class JAXRSApplication extends Application {
	@Override
	public Set<Class<?>> getClasses() {
		Set<Class<?>> classes = new HashSet<>();
		classes.add(CloudEventsProcessor.class);
		return classes;
	}

	@Override
	public Set<Object> getSingletons() {
		Set<Object> singletons = new HashSet<>();
		return singletons;
	}
}
