% Indoor tracking script

% Generate the path to the file
addpath(genpath('/Users/connormccann/Documents/BU/Fall_2016/EC544/EC544_demos/challenge_6/database'))

% Read the CSV into a table
T = readtable('beacon_rssi_data.txt','Delimiter',',','ReadVariableNames',false);

% Change the variable (column) names
T.Properties.VariableNames = {'Location','Beacon','RSSI'};

% Generate the avg table
uniqueLocations = unique(T.Location);
uniqueBeacons = unique(T.Beacon);
dataVec = zeros(1,4);


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
writetable(avgDB,'avgDB.txt','Delimiter',' ')

% k-nn look up within average database
sample = [43,64,75,63];
E_vec = zeros(1,height(avgDB));
for i = 1:height(avgDB)
    E_dist = 0;
    for j = 1:4
        var = sprintf('B%d',j);
        E_dist = E_dist + (sample(j) - avgDB.(var)(i))^2;
    end
    E_vec(i) = E_dist;
end
[M,I] = min(E_vec);

% determine the actual position
our_position = avgDB.Location(I)
        

