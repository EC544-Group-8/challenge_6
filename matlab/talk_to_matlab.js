
client = require('./client');
host='localhost';
port=5000;
c = new client(host, port);
c.receive();