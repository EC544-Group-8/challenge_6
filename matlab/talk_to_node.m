host='localhost';
port=5000;
s = server(host, port);
s.receive();
s.send('This is MatLab');

while(1)
    if(~s.Q.isempty())
        [p1,p2,p3] = s.findLocation(s.Q.back());
        %disp(s.Q.dequeue())
        disp([p1,p2,p3])
        s.send(num2str(p1));
    end
end
