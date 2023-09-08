<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Location Survey</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
	<script src="js/Winwheel.js"></script>
	<script src="js/TweenMax.min.js"></script>
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
    
    #spinwheel {
      position: absolute;
	  left: 0;
	  top: 0;
	  display: none;
      justify-content: center;
      align-items: center;
	  width: 90vw;
	  height: 90vh;
	  z-index: 10;
    }

	#spinwheelCanvasContainer {
		width: 438px;
		height: 582px;
		background-image: url(images/wheel_back.png);
		background-position: center;
    	background-repeat: none;
	}

	#canvas {
		width: 434px;
		height: 434px;
		margin-top: 75px;
		margin-left: 3px;
	}

	#spin {
		text-align: center;
		text-transform: capitalize;
		cursor: pointer;
		position: relative;
		left: 146px;
		top: -297px;
		width: 150px;
		height: 150px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 30px;
		color: white;
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
    		if (!qrcode.initialWidth) {
    			qrcode.initialWidth = current;
    		}
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
    
    function resetQRCode() {
    	var qrcode = document.getElementById("qrcode");
    	if (qrcode.initialWidth) {
        	qrcode.style.setProperty("width", qrcode.initialWidth + "px");
    	}
    }
    
    function makeQRSmall() {
    	var qrcode = document.getElementById("qrcode");
    	if (!qrcode.initialWidth) {
        	var styles = window.getComputedStyle(qrcode);
        	var maxWidth = styles.getPropertyValue("width");
        	if (maxWidth.includes("px")) {
        		var current = parseInt(maxWidth.substring(0, maxWidth.indexOf("px")));
    			qrcode.initialWidth = current;
        	}
    	}
    	qrcode.style.setProperty("width", "10px");
    }

	function hideQRCode() {
        document.getElementById("qrcode").style.setProperty("display", "none");
	}

	function showQRCode() {
		document.getElementById("qrcode").style.setProperty("display", "inherit");
	}
    
    function toggleSpinner() {
		let spinner = document.getElementById("spinwheel");
		var styles = window.getComputedStyle(spinner);
		if (styles.getPropertyValue("display") == "none") {
    		hideQRCode();
        	spinner.style.setProperty("display", "flex");

			// https://github.com/zarocknz/javascript-winwheel
			let currentColor = 0;
			const segmentColors = [
				'#ee1c24',
				'#3cb878',
				'#f6989d',
				'#00aef0',
				'#f26522',
				'#e70697',
				'#fff200',
				'#f6989d',
				'#ee1c24',
				'#3cb878',
				'#f26522',
				'#a186be',
				'#fff200',
				'#00aef0',
				'#ee1c24',
				'#f6989d',
				'#f26522',
				'#3cb878',
				'#a186be',
				'#fff200',
				'#00aef0',
			];
			let segments = [];
			let threshold = 0.25;
			let currentThreshold = threshold;
			let sourceData = [];
			if (window.surveyResults) {
				sourceData = [...window.surveyResults];
			}
			if (sourceData.length == 0) {
				sourceData = [
					{ name: "New York, NY" },
					{ name: "Los Angeles, CA" },
					{ name: "Chicago, IL" },
					{ name: "San Francisco, CA" },
					{ name: "London, England" },
					{ name: "Belin, Germany" },
					{ name: "Paris, France" },
					{ name: "Brussels, Belgium" },
					{ name: "Madrid, Spain" },
				];
			}
			const l = sourceData.length;
			const maxSegments = 25;
			for (let i = 0; i < l && i < maxSegments; i++) {
				if (i / l >= currentThreshold) {
					currentThreshold += threshold;
					segments.push({
						fillStyle: '#ffffff',
						text: 'TRY AGAIN',
						textFontSize: 14,
					});
				}
				let fontSize = null;
				let text = sourceData[i].name;
				if (text.length > 35) {
					fontSize = 3;
				} else if (text.length > 30) {
					fontSize = 4;
				} else if (text.length > 25) {
					fontSize = 5;
				} else if (text.length > 20) {
					fontSize = 6;
				} else if (text.length > 15) {
					fontSize = 8;
				} else if (text.length > 10) {
					fontSize = 9;
				} else if (text.length > 8) {
					fontSize = 14;
				} else {
					fontSize = 15;
				}
				segments.push({
					fillStyle: segmentColors[currentColor],
					text: text,
					textFontSize: fontSize,
				});
				if (currentColor == segmentColors.length - 1) {
					currentColor = 0;
				} else {
					currentColor++;
				}
			}
			console.dir(segments);
			window.theWheel = new Winwheel({
                outerRadius: 212,
                innerRadius: 75,
                textFontSize: 24,
                textOrientation: 'vertical',
                textAlignment: 'outer',
                numSegments: segments.length,
                segments: segments,
                animation: {
                    type: 'spinToStop',
                    duration: 10,
                    spins: 3,
                    callbackFinished: spinCompleted,
                },
                pins:
                {
                    number: segments.length,
                    fillStyle: 'silver',
                    outerRadius: 4,
                }
            });

    	} else {
        	spinner.style.setProperty("display", "none");
			showQRCode();
    	}
    }

	function spin() {
		window.theWheel.stopAnimation(false);
		window.theWheel.rotationAngle = 0;
		window.theWheel.draw();
		window.theWheel.startAnimation();
	}

	function spinCompleted(segment) {
		alert(segment.text);
	}

	function farthestDistance() {
		if (window.surveyResults) {
			let farthest = null;
			for (let surveyResult of window.surveyResults) {
				if (farthest) {
					if (surveyResult.distance > farthest.distance) {
						farthest = surveyResult;
					}
				} else {
					farthest = surveyResult;
				}
			}
			alert("Farthest location: " + farthest.name + " at " + (farthest.distance / 1000).toLocaleString(undefined, { maximumFractionDigits: 0 }) + "km")
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
	      <span class="pseudobutton" onclick="increaseQRCode()" title="Increase QR Code Size">+</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="decreaseQRCode()" title="Decrease QR Code Size">-</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="resetQRCode()" title="Reset QR Code Size">↺</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="makeQRSmall()" title="Minimize QR Code Size">🔍</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="toggleSpinner()" title="Toggle Spinner">⥁</span>
	      &nbsp;
	      <span class="pseudobutton" onclick="farthestDistance()" title="Farthest Distance">📏</span>
	    </div>
    </div>
	<div id="spinwheel">
		<div id="spinwheelCanvasContainer">
			<canvas id="canvas" width="434" height="434">
				<p style="background-color: white; color: red;" align="center">Please use a browser that supports the canvas element</p>
			</canvas>
			<div id="spin" onclick="spin()">Spin</div>
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
    		  i = str.indexOf(' ');
    		  var distance = parseFloat(str.substring(0, i));
    		  str = str.substring(i + 1);
    		  
    		  if (!window.surveyResults) {
    			  window.surveyResults = [];
    		  }
    		  window.surveyResults.push({
    		    latitude: latitude,
    		    longitude: longitude,
    		    distance: distance,
    		    name: str,
    		  });
    		  
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
