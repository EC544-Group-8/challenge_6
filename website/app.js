var SerialPort = require("serialport");
var express = require('express');
var app = express();
var http = require('http').Server(app);
var portName = process.argv[2],
portConfig = {
	baudRate: 9600,
	parser: SerialPort.parsers.readline("\n")
};
var sp = new SerialPort.SerialPort(portName, portConfig);

app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res){
  res.sendfile('index.html');
});


http.listen(3000, function(){
  console.log('listening on *:3000');
});

var bin_id = '0';

// Receive matlab results of location
sp.on("open", function () {
  console.log('open');
  sp.on('data', function(data) {
    console.log('data received: ');
    console.log(data[0]);
    bin_id = data[0];
  });
});

// --------- DEFINE AJAX POST REQUESTS HERE --------- //
// For getting the updated location of the moving device
app.get('/get_location', function(req, res){
	// Send matlab the current RSSI readings
	sp.write('60,70,72,45');
	console.log('trying to send current RSSI data: ');

	// This bin_id is to be obtained from matlab, then returned to the front end
	setTimeout(function() {
		console.log('ok waited 1/2 sec...');
		// Let the main.js know that the AJAX worked
		bin_id = '24'; // TODO! Update this with the actual values
		res.send(bin_id);
	},500);
});

