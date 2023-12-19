let ws = undefined;

window.onload = function () {
  WebSocketStart();
};

window.onunload = function () {
  WebSocketStop();
};

function WebSocketStart() {
  ws = new WebSocket("ws://" + window.location.host + "/session");
  ws.onopen = () => {
    console.log("Socket is opened.");
    const counterDisplay = document.getElementById("counterDisplay");
    ws.send(counterDisplay.innerText)
    ws.send("INITIATE");
  };

  ws.onmessage = (event) => {
      updateCounterDisplay(event.data);
      console.log(event.data);
  };

  ws.onclose = () => {
    console.log("Socket is closed.");
  };
}

function WebSocketStop() {
  if (ws !== undefined) {
    ws.close();
  }
}

// Function to update the counter display on the webpage
function updateCounterDisplay(data) {
  const counterDisplay = document.getElementById("counterDisplay");
    counterDisplay.innerText = `${data}`;
}

function decreaseCounter() {
  if (ws !== undefined) {
    ws.send("DECREASE");
    console.log("decreased");
  }
}

function increaseCounter() {
  if (ws !== undefined) {
    ws.send("INCREASE");
    console.log("increased");
  }
}

var buttoninc = document.getElementById("button.increase");
var buttondec = document.getElementById("button.decrease");

buttoninc.addEventListener("click", increaseCounter);
buttondec.addEventListener("click", decreaseCounter);
