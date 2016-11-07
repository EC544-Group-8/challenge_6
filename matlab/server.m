function s = server(host, port)
    s.Q = Queue();
    s.socket = tcpip(host,port,'NetworkRole','Server');
    set(s.socket, 'InputBufferSize', 3000000);
    set(s.socket, 'OutputBufferSize', 3000000);
    fopen(s.socket);

    s.send = @send;
    function send(data)
        d = whos(data);
        fwrite(s.socket, data, d.class);
    end

    s.receive = @receive;
    function receive()
        TimerFcn = {@recv, s.socket, s.Q};
        t = timer('ExecutionMode', 'FixedRate', ...
            'Period', 1, ...
            'TimerFcn', TimerFcn);
        start(t);
    end

    s.disconnect = @disconnect;
    function disconnect()
        fclose(s.socket);
        delete(s.socket);
        clear s.socket;
    end

    s.findLocation = @findLocation;
    function our_position = findLocation(in) % originally has argument called sample

        sample = str2num(in);

        raw = true;
        %sample = dequ
        % Generate the path to the file
        %addpath(genpath('/Users/connormccann/Documents/BU/Fall_2016/EC544/EC544_demos/challenge_6/database'))
        %format shortg

        % Read the CSV into a table
        T = readtable('beacon_rssi_data.txt','Delimiter',',','ReadVariableNames',false);

        % Change the variable (column) names
        T.Properties.VariableNames = {'Location','Beacon','RSSI'};

        % Generate the avg table
        uniqueLocations = unique(T.Location);
        uniqueBeacons = unique(T.Beacon);
        dataVec = zeros(1,4);
        if(~raw)
            % Pre-allocate the table
            avgDB = table();
            avgDB.Location = zeros(length(uniqueLocations),1);
            avgDB.B1 = zeros(length(uniqueLocations),1);
            avgDB.B2 = zeros(length(uniqueLocations),1);
            avgDB.B3 = zeros(length(uniqueLocations),1);
            avgDB.B4 = zeros(length(uniqueLocations),1);

            for i = 1:length(uniqueLocations)
                for j = 1:length(uniqueBeacons)
                    dataVec(j) = floor(100*mean(T.RSSI(T.Location == i & T.Beacon == j)))/100;
                end
                avgDB.Location(i) = i';
                avgDB.B1(i) = dataVec(1);
                avgDB.B2(i) = dataVec(2);
                avgDB.B3(i) = dataVec(3);
                avgDB.B4(i) = dataVec(4);
            end

            % save table to excel sheet
            %writetable(avgDB,'avgDB.txt','Delimiter',' ')

            % sample
            %sample = [38,63,70,45];

            % vectorized knn position from average database 
            [min_val,our_position] = min(sum((table2array(avgDB(:,2:5)) - repmat(sample,height(avgDB),1)).^2,2)');

            % display the result of average database
            %disp(our_position)
        else
            % knn through the RAW database
            min_total_E_dist = 10000;
            for i = 1:length(uniqueLocations)
                total_E_dist = 0;
                for j = 1:4
                    RSSI_vec = T.RSSI(T.Location == i & T.Beacon == j);
                    E_dist = (sample(j) - RSSI_vec).^2;
                    [min_E_dist,I] = min(E_dist);
                    total_E_dist = total_E_dist + min_E_dist;
                end
                if(total_E_dist < min_total_E_dist)
                    min_total_E_dist = total_E_dist;
                    our_position = i;
                end
            end
        end
    end
end

% subfunctions-------------------------------------------------------------
function Q = recv(hobj, eventdata, socket, Q)
    while(socket.BytesAvailable > 0)
        data = fgetl(socket);
        Q.enqueue(data);
        %fprintf('%s\n', data)  
    end
end
