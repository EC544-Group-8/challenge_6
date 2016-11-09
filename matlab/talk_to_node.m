%==========================================================================
%                           Build Knn Model
%==========================================================================
% read the CSV into a table
T = readtable('../database/beacon_rssi_data.txt','Delimiter',',','ReadVariableNames',false);

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
       species = [species;location];
       new_row = [0 0 0 0];
   end

end

% clean up first rows
meas(1,:)=[];
species(1,:)=[];

% make knn model
Mdl = fitcknn(meas,species,'NumNeighbors',3);


%==========================================================================
%                           Build avgDB Model
%=========================================================================
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


%==========================================================================
%                               Server
%==========================================================================
host='localhost';
port=5000;
s = server(host, port, Mdl, avgDB);
s.receive();
s.send('This is MatLab');


%==========================================================================
%                        Communicat with Node.js
%==========================================================================
historic = buffer(0);
while(1)
    % if queue is not empty
    if(~s.Q.isempty())
        
        % estimate location with knns
        [P1,P2] = s.findLocation(s.Q.dequeue());
        % dispaly on our console here
        disp([P1,P2])
        
        % check if we trust the new location
        if(~isempty(find(historic)))
            lastLoc = historic(1);
            delta_pos = abs(P1 - lastLoc);
            if(delta_pos <= 2 || delta_pos >= 5) % We trust this range
                 historic = buffer(P1); 
                 data = P1;
            else
                data = lastLoc; % otherwise send the historic data instead
            end
        else
            % this is for the first runtime condition 
            historic = buffer(P1); 
            data = P1;
        end
        
        % send the data we trust
        s.send(num2str(data));
           
    end
end
