package com.example.demo.websockets;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

import jakarta.websocket.EncodeException;
import jakarta.websocket.OnClose;
import jakarta.websocket.OnError;
import jakarta.websocket.OnMessage;
import jakarta.websocket.OnOpen;
import jakarta.websocket.Session;
import jakarta.websocket.server.ServerEndpoint;

/**
 * https://blogs.oracle.com/javamagazine/post/how-to-build-applications-with-the-websocket-api-for-java-ee-and-jakarta-ee
 */
@ServerEndpoint("/GeolocationWebSocket")
public class GeolocationWebSocket {
	private static final ConcurrentHashMap<String, Session> sessions = new ConcurrentHashMap<>();
	private static final ConcurrentHashMap<String, TestMessageSender> testSenders = new ConcurrentHashMap<>();

	@OnOpen
	public void onOpen(Session session) throws IOException, EncodeException {
		System.out.println("GeolocationWebSocket received new session: " + session.getId());
		sessions.put(session.getId(), session);

		TestMessageSender testSender = new TestMessageSender(session.getId());
		testSenders.put(session.getId(), testSender);
		testSender.start();
	}

	@OnMessage
	public void onBrowserMessage(Session session, String message) {
		System.out.println("GeolocationWebSocket received message from " + session.getId() + ": " + message);
	}

	@OnClose
	public void onClose(Session session) {
		System.out.println("GeolocationWebSocket closing session: " + session.getId());
		sessions.remove(session.getId());
		TestMessageSender testSender = testSenders.remove(session.getId());
		if (testSender != null) {
			testSender.stopRunning();
		}
	}

	@OnError
	public void onError(Session session, Throwable throwable) {
		System.out.println("GeolocationWebSocket error on session: " + session.getId() + ": " + throwable);
		throwable.printStackTrace();
	}

	public static final void sendMessageToBrowser(String sessionId, String text) throws IOException {
		Session session = sessions.get(sessionId);
		if (session != null) {
			session.getBasicRemote().sendText(text);
		}
	}
}
