function blobToJson(blob) {
    return new Promise((resolve, reject) => {
        let fr = new FileReader();
        fr.onload = () => {
            resolve(JSON.parse(fr.result));
        };
        fr.readAsText(blob);
    });
}

function uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16));
}

WebSocket.prototype.sendJsonBlob = function(data) {
    const string = JSON.stringify({ client: uuid, data: data })
    const blob = new Blob([string], { type: "application/json" });
    this.send(blob)
};

const uuid = uuidv4()
let ws = undefined

function WebSocketStart() {
    ws = new WebSocket("ws://" + window.location.host + "/session")
    ws.onopen = () => {
        console.log("Socket is opened.");
        ws.sendJsonBlob({ connect: true })
    }

    ws.onmessage = (event) => {
        blobToJson(event.data).then((obj) => {
            // Update the counter value on the webpage
            updateCounterDisplay(obj);
            console.log("Message received.");
        })
    };

    ws.onclose = () => {
        console.log("Socket is closed.");
    };
}

function WebSocketStop() {
    if (ws !== undefined) {
        ws.close()
    }
}

// Function to update the counter display on the webpage
function updateCounterDisplay(data) {
    const counterDisplay = document.getElementById('counterDisplay');
    if (counterDisplay && Array.isArray(data) && data.length > 0) {
        const firstItem = data[0];
        if (firstItem && firstItem.clubNight && firstItem.clubNight.currentGuests !== undefined) {
            const currentGuests = firstItem.clubNight.currentGuests;
            counterDisplay.innerText = `Current Guests: ${currentGuests}`;
        } else {
            console.error('Invalid data format or missing properties in array:', data);
        }
    } else {
        console.error('Invalid data format or missing properties:', data);
    }
}

function increase() {
    ws.sendJsonBlob({ button: 'increase', increasPressed: true});
    console.log('increased');
    ws.sendJsonBlob({ button: 'increase', increasPressed: false});
}

function decrease() {
    ws.sendJsonBlob({ button: 'decrease', decreasePressed: true});
    console.log('decreased');
    ws.sendJsonBlob({ button: 'decrease', decreasePressed: false});
}

