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
    </style>
  </head>
  <body>
    <div class="flexContainer">
    	<header>
    		<h1>Location Survey</h1>
    	</header>
    	<main id="map">
    	</main>
	    <footer>
	    	<p id="results">Waiting for first result</p>
	    </footer>
    </div>
    <script>
      function appendResults(str) {
    	  var results = document.getElementById("results");
    	  if (results.initialized) {
    		  results.innerHTML = str + "<br />" + results.innerHTML;
    	  } else {
    		  results.innerHTML = str;
    		  results.initialized = true;
    	  }
      }
      
      function openWebSocket() {
    	  try {
        	  if ('WebSocket' in window || 'MozWebSocket' in window) {
            	  var websocketUrl = "ws://" + window.location.host + "/GeolocationWebSocket";
            	  console.log("Initiating web socket to " + websocketUrl);
            	  
                  ws = new WebSocket(websocketUrl);
                  
                  ws.onopen = function () {
                	  console.log("WebSocket successfully opened");
                  };

                  ws.onmessage = function (evt) {
                	  console.log("WebSocket received message");
                	  console.log(evt);
                	  handleResult(evt.data);
                  };

                  ws.onclose = function () {
                	  appendResults("WebSocket closed");
                  };
              } else {
        		  appendResults("ERROR: WebSockets not supported or not enabled in this browser.");
        	  }
          } catch (e) {
        	  handleException(e);
          }
      }
      
      async function handleResult(str) {
    	  let i = str.indexOf(' ');
    	  if (i != -1) {
	    	  const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
	    	  const { InfoWindow } = await google.maps.importLibrary("maps")

	    	  let latitude = parseFloat(str.substring(0, i));
    		  str = str.substring(i + 1);
    		  i = str.indexOf(' ');
    		  let longitude = parseFloat(str.substring(0, i));
    		  str = str.substring(i + 1);
        	  appendResults("Welcome from " + str + " (" + new Date().toLocaleTimeString() + ")");
        	  
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
      ({key: "<%= System.getenv("GOOGLE_API_KEY") %>", v: "weekly"});
      
      initMap();
      
    </script>
  </body>
</html>
