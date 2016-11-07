host='localhost';
port=5000;
s = server(host, port);
s.receive();
s.send('This is MatLab');

while(1)
    if(~s.Q.isempty())
        pos = s.findLocation(s.Q.dequeue());
        disp(pos)
        s.send(num2str(pos));
    end
end
