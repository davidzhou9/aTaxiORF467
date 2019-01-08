%% read in data

routes = readtable('routes.txt');
trips = readtable('trips.txt');
stopTimes = readtable('stop_times.txt');
stops = readtable('stops.txt');

%% cleaning
outputTable = cell(20000, 3);
index = 1;

for i = 1:height(routes)
    transitType = routes(i, 2);
    routeID = routes{i, 6};
    indTrips = table2array(trips(:,3)) == routeID;
    tripIDSet = trips(indTrips, 10);
    
    tempStopTimes = stopTimes.trip_id;
    tempTripIDS = table2array(tripIDSet);
    
    stopIDS = stopTimes(ismember(tempStopTimes, tempTripIDS), 4);
    
    dataIndices = ismember(stops.stop_id, table2array(stopIDS));
    cleanedStops = stops(dataIndices, :);
    
    for j=1:height(cleanedStops)
        outputTable(index, 2) = num2cell(cleanedStops{j, 1});
        outputTable(index, 3) = num2cell(cleanedStops{j, 4});
        outputTable(index, 4) = num2cell(transitType{1,1});
        outputTable(index, 1) = cellstr(int2str(cleanedStops{j, 3}));
        index = index + 1;
    end
end
%%
[C,ia,ic] = unique(outputTable(:,1));
outputTable = outputTable(ia, :);
finalTable = cell2table(outputTable);
writetable(finalTable, 'HTXPublicTransit.csv');
