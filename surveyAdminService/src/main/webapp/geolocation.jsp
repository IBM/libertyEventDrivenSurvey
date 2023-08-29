<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Location Survey</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
    <style>
    html, body {
      height: 100vh;
      margin: 0;
      font-family: monospace;
    }
    
    .flexContainer {
      display: flex;
      flex-direction: column;
      height: 100%;
      position: relative;
    }
    
    main {
      flex: 1;
      border-top: 1px solid black;
      border-bottom: 1px solid black;
    }
    
    header {
    	padding: 10px;
    }
    
    header {
    	align-self: center;
    }
    
    footer {
    	max-height: 100px;
    	overflow: auto;
    	text-align: center;
    	width: 100%;
    }

    h1 {
    	margin: 0;
    }
    
    #qrcode {
    	position: absolute;
    	bottom: 0;
    	left: 0;
    	height: auto;
    }
    
    #sizecontrols {
    	position: absolute;
    	bottom: 0;
    	left: 10px;
    	display: flex;
    	flex-direction: row;
    }
    
    .pseudobutton {
    	cursor: pointer;
    	font-size: x-small;
    }
    </style>
    <script>
    function increaseQRCode() {
    	resizeQRCode(true);
    }
    function decreaseQRCode() {
    	resizeQRCode(false);
    }
    function resizeQRCode(increase) {
    	var qrcode = document.getElementById("qrcode");
    	var styles = window.getComputedStyle(qrcode);
    	var maxWidth = styles.getPropertyValue("width");
    	if (maxWidth.includes("px")) {
    		var current = parseInt(maxWidth.substring(0, maxWidth.indexOf("px")));
    		if (increase) {
    			current = parseInt(current * 1.1);
    		} else {
    			current = parseInt(current * 0.9);
    		}
    		qrcode.style.setProperty("width", current + "px");
    	} else {
    		alert("Unknown max-width format: " + maxWidth);
    	}
    }
    </script>
  </head>
  <body>
    <div class="flexContainer">
    	<header>
    		<h1>Location Survey</h1>
    	</header>
    	<main id="map">
    	</main>
	    <footer>
	    	<p id="results">&nbsp;</p>
	    </footer>
	    <img id="qrcode" src="qrcode.png" width="<%= com.example.demo.Configuration.QRCODE_WIDTH %>" />
	    <div id="sizecontrols">
	      <span class="pseudobutton" onclick="increaseQRCode()">+</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="decreaseQRCode()">-</span>
	    </div>
    </div>
    <script>
      function appendResults(str) {
    	  str = str + " (" + new Date().toLocaleTimeString() + ")";
    	  var results = document.getElementById("results");
    	  if (results.initialized) {
    		  results.innerHTML = str + "<br />" + results.innerHTML;
    	  } else {
    		  results.innerHTML = str;
    		  results.initialized = true;
    	  }
      }
      
      function pingWebSocket() {
    	  if (window.ws && window.wsready) {
    		  window.ws.send("PING");
    	  }
      }
      
      function tryReconnectWebSocket() {
    	  window.reconnecting = true;
    	  openWebSocket();
      }
      
      function openWebSocket() {
    	  try {
        	  if ('WebSocket' in window || 'MozWebSocket' in window) {
        		  if (!window.wsconnecting) {
	        		  window.wsconnecting = true;
	        		  
	            	  var websocketUrl = window.location.protocol === 'https:' ? "wss://" : "ws://";
	            	  websocketUrl += window.location.host + "/GeolocationWebSocket";
	            	  console.log("Initiating web socket to " + websocketUrl);
	            	  
	            	  if (window.reconnecting) {
	            		  appendResults("Reconnecting...");
	            	  }
	            	  
	                  window.ws = new WebSocket(websocketUrl);
	                  
	                  window.ws.onopen = function () {
	                	  console.log("WebSocket successfully opened");
	                	  
	                	  window.wsready = true;
	                	  window.wsconnecting = false;
	                	  
	                	  appendResults("<%= com.example.demo.Configuration.isGoogleAPIKeyConfigured() ? "Connected" : "Error: GOOGLE_API_KEY not specified" %>");
	                	  
	                	  // Some environments aggressively clean up idle sockets
	                	  // and WebSockets are not immune, so we just send
	                	  // a dummy ping message periodicaly
	                	  setInterval(pingWebSocket, 15000);
	                  };
	
	                  window.ws.onmessage = function (evt) {
	                	  console.log("WebSocket received message");
	                	  console.log(evt);
	                	  handleResult(evt.data);
	                  };
	
	                  window.ws.onerror = function (evt) {
	                	  window.ws = null;
	                	  window.wsready = false;
	                	  window.wsconnecting = false;
	                	  console.log("WebSocket error");
	                	  console.log(evt);
	                	  handleResult("ERROR: WebSocket received an error");
	                	  setTimeout(tryReconnectWebSocket, 5000);
	                  };
	
	                  window.ws.onclose = function (evt) {
	                	  window.ws = null;
	                	  window.wsready = false;
	                	  window.wsconnecting = false;
	                	  console.log("WebSocket close");
	                	  console.log(evt);
	                	  
	                	  // https://www.rfc-editor.org/rfc/rfc6455#section-7.4.1
	                	  appendResults("Warning: WebSocket closed (" + evt.code + ")");
	                	  
	                	  // A close can either happen as the browser is refreshing or navigating
	                	  // away, which is normal, or for some problematic reason.
	                	  // To avoid handling the former case, we only try re-starting the
	                	  // connection after a bit of time.
	                	  setTimeout(tryReconnectWebSocket, 5000);
	                  };        			  
        		  }
              } else {
        		  appendResults("ERROR: WebSockets not supported or not enabled in this browser.");
        	  }
          } catch (e) {
        	  handleException(e);
          }
      }
      
      async function handleResult(str) {
    	  var i = str.indexOf(' ');
    	  if (i != -1) {
	    	  const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
	    	  const { InfoWindow } = await google.maps.importLibrary("maps")

	    	  var latitude = parseFloat(str.substring(0, i));
    		  str = str.substring(i + 1);
    		  i = str.indexOf(' ');
    		  var longitude = parseFloat(str.substring(0, i));
    		  str = str.substring(i + 1);
    		  
    		  if (str.indexOf("received an error") == -1) {
            	  appendResults("Welcome: " + str);
    		  } else {
            	  appendResults(str);
    		  }
        	  
        	  const marker = new AdvancedMarkerElement({
       		    map: window.map,
       		    position: { lat: latitude, lng: longitude },
       		    title: str,
       		  });
        	  
        	  const infowindow = new google.maps.InfoWindow({
       		    content: str,
       		  });
        	  
        	  marker.addListener("click", () => {
       		    infowindow.open({
       		      anchor: marker,
       		      map,
       		    });
       		  });
    	  }
      }
      
      function handleException(e) {
    	  appendResults("ERROR: " + e);
      }
      
      async function initMap() {
    	  try {
	    	  const { Map } = await google.maps.importLibrary("maps");

	    	  window.map = new Map(document.getElementById("map"), {
	    		    center: { lat: 39.02035726090001, lng: -36.31471803232274 },
	    		    zoom: 3,
	    		    mapId: "locationSurvey",
	    	  });
	    	  
	    	  openWebSocket();
    	  } catch (e) {
    		  handleException(e);
    	  }
      }
      
      // Load Google Maps JS API
      (g=>{var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.\${c}apis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})
      ({key: "<%= com.example.demo.Configuration.getGoogleAPIKey() %>", v: "weekly"});
      
      initMap();
      
    </script>
  </body>
</html>
