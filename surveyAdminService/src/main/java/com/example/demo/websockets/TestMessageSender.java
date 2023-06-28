package com.example.demo.websockets;

import java.time.Instant;

public class TestMessageSender extends Thread {
	private String sessionId;
	private volatile boolean running = true;

	public TestMessageSender(String sessionId) {
		super(TestMessageSender.class.getName() + " for " + sessionId);
		this.sessionId = sessionId;
	}

	public void stopRunning() {
		running = false;
	}

	@Override
	public void run() {
		while (running) {
			try {
				Thread.sleep(30000);

				GeolocationWebSocket.sendMessageToBrowser(sessionId, "Hello World @ " + Instant.now());
			} catch (Throwable t) {
				t.printStackTrace();
			}
		}
	}
}
