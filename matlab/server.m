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
    
    function [our_position,P1,P2] = findLocation(in) 
        
        % measurements
        % take T and make a list of measurments with 1 sample from each beacon

        % species
        % for each corresponding row in T, this lists the location
        
        % Read the CSV into a table
        T = readtable('../database/beacon_rssi_data.txt','Delimiter',',','ReadVariableNames',false);
        
        sample = str2num(in);

        [r,c] = size(T);
        meas = [0,0,0,0];
        species = [0];
        new_row = [0 0 0 0];

        for i = 1:r
           row = T(i,:);
           location = row{:,1};
           beacon = row{:,2};
           RSSI = row{:,3};

           % add reading to corresponding column of new row
           new_row(:,beacon) = RSSI;
           if(new_row > 0) % if all elements are non-zero
               % push to measurements and and reset new row
               meas = [meas;new_row];
               species = [species;location]; % need to make sure all have 4? TODO
               new_row = [0 0 0 0];
           end

        end

        % clean up first rows
        meas(1,:)=[];
        species(1,:)=[];


        % make knn model
        Mdl = fitcknn(meas,species,'NumNeighbors',3);

        % predict a value
        m1 = 78;
        m2 = 54;
        m3 = 49;
        m4 = 62;
        m = [m1,m2,m3,m4];
        bin = predict(Mdl,sample);  
        our_position = bin;
        
        %==================================================================
        % Change the variable (column) names
        T.Properties.VariableNames = {'Location','Beacon','RSSI'};

        % Generate the avg table
        uniqueLocations = unique(T.Location);
        uniqueBeacons = unique(T.Beacon);
        dataVec = zeros(1,4);

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

        % vectorized knn position from average database 
        [min_val,P1] = min(sum((table2array(avgDB(:,2:5)) - repmat(sample,height(avgDB),1)).^2,2)');

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
                P2 = i;
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
