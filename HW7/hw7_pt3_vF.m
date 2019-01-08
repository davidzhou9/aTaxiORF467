%% part a

% this part is for reading in the csv file
data = readtable('NorthCarolina37129Module1NN2ndRun.csv');
dataMatrix = table2array(data);

%% part b
% this part is for determining HHIncome and appending it to each person

income = [];
decile = [];
final_decile = [];
hhid = [];
r = 1;
while (r <= length(data.HHID))
    sum = 0;
    household = data.HHID(r);
    hhid = [hhid; household];
    i = r;
    while(r <= length(data.HHID) & data.HHID(r) == household)
        sum = sum + data.IncomeAmount(r);
        r = r + 1;
    end
    decile = [decile; sum];
    for j = i:(r-1)
        income = [income; sum];
    end
end

data.HHIncome = income;
hh = table(hhid);
hh.HHIncome = decile;
decile = sort(decile);
tenth = floor(length(decile)/10);
fin = 0;
for k = 1:length(hh.HHIncome)
    for h = 1:10
        if hh.HHIncome(k) > decile(h*tenth)
            fin = h + 1;
        else
            fin = fin;
        end
    end
    final_decile = [final_decile; fin];
end 

hh.HHIncomeDecile = final_decile;


%% part c
% this part is for vehicle ownership, you can change the rates to match
% your area

%P(2) = 0.65
%P(1) = 0.35
%P(0) = 0.10
auto = [];

for i = 1:length(hh.HHIncomeDecile)
    x = rand(1,1);
    if x > 0.9
        auto = [auto; 0];
    elseif x < 0.35
        auto = [auto; 1];
    else
        auto = [auto; 2];
    end
end

hh.AutoOwnership = auto;

%% part d 
%this part is for bus and train stops, input your own transit stop data
dataBusStops = readtable('WilmingtonPublicTransit.csv');
xpix = [];
ypix = [];
r = 1;
while (r <= length(data.HHID))
    sum = 0;
    household = data.HHID(r);
    i = r;
    while(r <= length(data.HHID) & data.HHID(r) == household)
        r = r + 1;
    end
    xpix = [xpix; floor(138.348*(data.Longitude(i) + 97.5) * cos(data.Latitude(i) * pi()/180))];
    ypix = [ypix; floor(138.348*(data.Latitude(i)- 37))];
end

hh.xPixel = xpix;
hh.yPixel = ypix;

busScore = [];
for j = 1:length(hh.HHIncomeDecile)
    sum = 0;
    for k = 1:length(dataBusStops.xPixel)
        if dataBusStops.xPixel(k) == hh.xPixel(j) & dataBusStops.yPixel(k) == hh.yPixel(j)
            if dataBusStops.TransitType(k) == 1 
                sum = 1;
            else
                sum = 10;
            end
        else
            sum = sum;
        end
    end
    if sum == 0
        busScore = [busScore; 0];
    elseif sum == 1
        busScore = [busScore; 5];
    else 
        busScore = [busScore; 10];
    end
end

hh.busStops = busScore;
        
%% part e
%this part creates the mobility index and determines lowest decile

mobility = [];
for i = 1:length(hh.HHIncomeDecile)
    mobility = [mobility; hh.HHIncomeDecile(i) + hh.AutoOwnership(i) + hh.busStops(i)];
end

hh.MI = mobility;
hh(1:15,:);
sorteddata = sortrows(hh,8);
lowestdecile = sorteddata;
lowestdecile([tenth:length(hh.HHIncome)], :) = [];


%% write lowest decile to csv and xls without trips
writetable(lowestdecile, 'NorthCarolina_37129_Lowest_MobilityIndex.csv');
writetable(lowestdecile, 'NorthCarolina_37129_Lowest_MobilityIndex.xlsx');

writetable(sorteddata, 'NorthCarolina_37129_MI.xlsx');


dataTripsPixel = readtable('NorthCarolina_37129_Module6NN1stRun.csv');
 
%clean trip data to lowest decile
cleanedTrips = dataTripsPixel(ismember(dataTripsPixel.HHID, lowestdecile.hhid),:);
writetable(cleanedTrips, 'NorthCarolina_37129_LowestMI.csv');
writetable(cleanedTrips, 'NorthCarolina_37129_LowestMI.xlsx');


%% # of trips x max of 7 trips + 1 for column headers = max number of rows with 10 column fields
peopleInPixelTrips = cell(18380, 10); %19435 comes from examining my matrix, will vary for others
step = 9; % column of next node name is 9 cols over
outputIndex = 2;

%set the column headers
peopleInPixelTrips{1, 1} = 'Person ID';
peopleInPixelTrips{1, 2} = 'oXPixel';
peopleInPixelTrips{1, 3} = 'oYPixel';
peopleInPixelTrips{1, 4} = 'oName';
peopleInPixelTrips{1, 5} = 'oTime';
peopleInPixelTrips{1, 6} = 'dXPixel';
peopleInPixelTrips{1, 7} = 'dYPixel';
peopleInPixelTrips{1, 8} = 'dName';
peopleInPixelTrips{1, 9} = '1 Column';
peopleInPixelTrips{1, 10} = 'Distance in Miles';

for row = 1:height(cleanedTrips)
    dTimeCheck = cleanedTrips{row, 16};
    dTime = dTimeCheck{1,1};
    % if person has no trips, then just set corresponding row
    if strcmp(dTime, 'dTime') == 1
        peopleInPixelTrips(outputIndex, 1) = num2cell(cleanedTrips{row, 6}); % get personIDnumber
        peopleInPixelTrips(outputIndex, 9) = num2cell(1);
        outputIndex = outputIndex + 1;
        continue;
    end
    
    %since first trip origin is in integer format, we parse differently
    %than for later column trips
    peopleInPixelTrips(outputIndex, 1) = num2cell(cleanedTrips{row, 6}); % get personIDnumber    
    oLat = cleanedTrips{row, 13}; 
    oLong = cleanedTrips{row, 14}; 
    oXPixel = floor(138.348*(oLong + 97.5)*cos(oLat * pi/180));
    oYPixel = floor(138.348*(oLat - 37));
    peopleInPixelTrips(outputIndex, 2) = num2cell(oXPixel);
    peopleInPixelTrips(outputIndex, 3) = num2cell(oYPixel);
    oName = cleanedTrips{row, 11};
    peopleInPixelTrips(outputIndex, 4) = oName;
       
    % getting time
    dTime = cleanedTrips{row, 16};
    peopleInPixelTrips(outputIndex, 5) = dTime;
    
    % getting destination coordinates
    latIndexNext = 22;
    longIndexNext = 23;
    dLatTemp = cleanedTrips{row, latIndexNext};
    dLongTemp = cleanedTrips{row, longIndexNext};
    dLat = str2double(dLatTemp{1,1});
    dLong = str2double(dLongTemp{1,1});
    dXPixel = floor(138.348*(dLong + 97.5)*cos(dLat * pi/180));
    dYPixel = floor(138.348*(dLat - 37));
    peopleInPixelTrips(outputIndex,6) = num2cell(dXPixel);
    peopleInPixelTrips(outputIndex,7) = num2cell(dYPixel);
       
    % getting destination name
    dName = cleanedTrips{row, 20};
    peopleInPixelTrips(outputIndex, 8) = dName;
    peopleInPixelTrips(outputIndex, 9) = num2cell(1);
    distMi = 0.5 * sqrt((dXPixel - oXPixel)^2 + (dYPixel - oYPixel)^2);
    peopleInPixelTrips(outputIndex, 10) = num2cell(distMi);
    outputIndex = outputIndex + 1;
    
    % index of column of Node2Name    
    colIndex = 20;
    departureTimeIndex = colIndex + 5;
    
    dTimeCheck = cleanedTrips{row, departureTimeIndex};
    dTime = dTimeCheck{1,1};
    %begin loop
    while strcmp('NA', dTime) == 0 && strcmp('dTime', dTime) == 0 
        % getting origination name
        oName = cleanedTrips{row, colIndex};
        peopleInPixelTrips(outputIndex, 4) = oName; %oNameMat(1,1);
        
        % getting origination coordinates
        latIndex = colIndex + 2;
        longIndex = colIndex + 3;
        oLatTemp = cleanedTrips{row, latIndex};
        oLongTemp = cleanedTrips{row, longIndex};
        oLat = str2double(dLatTemp{1,1});
        oLong = str2double(dLongTemp{1,1});
        oXPixel = floor(138.348*(oLong + 97.5)*cos(oLat * pi/180));
        oYPixel = floor(138.348*(oLat - 37));
        peopleInPixelTrips(outputIndex, 2) = num2cell(oXPixel);
        peopleInPixelTrips(outputIndex, 3) = num2cell(oYPixel);
        
        peopleInPixelTrips(outputIndex, 5) = cleanedTrips{row, colIndex + 5}; %departure time
        
        % break the loop if we've hit the 7th node
        if colIndex == 65
            break;
        end
        
        % getting destination coordaintes
        latIndexNext = latIndex + step;
        longIndexNext = longIndex + step;
        dLatTemp = cleanedTrips{row, latIndexNext};
        dLongTemp = cleanedTrips{row, longIndexNext};
        dLat = str2double(dLatTemp{1,1});
        dLong = str2double(dLongTemp{1,1});
        dXPixel = floor(138.348*(dLong + 97.5)*cos(dLat * pi/180));
        dYPixel = floor(138.348*(dLat - 37));
        peopleInPixelTrips(outputIndex, 6) = num2cell(dXPixel);
        peopleInPixelTrips(outputIndex, 7) = num2cell(dYPixel);
        
        % getting destination name
        dName = cleanedTrips{row, colIndex + step};
        peopleInPixelTrips(outputIndex, 8) = dName;
        
        % setting the one in the ones column
        peopleInPixelTrips(outputIndex, 9) = num2cell(1);
       
        % getting cartesian distance
        distMi = 0.5 * sqrt((dXPixel - oXPixel)^2 + (dYPixel - oYPixel)^2);
        peopleInPixelTrips(outputIndex, 10) = num2cell(distMi);
        
        % updating index values
        colIndex = colIndex + step;
        outputIndex = outputIndex + 1;
        dTimeCheck = cleanedTrips{row, colIndex + 5};
        dTime = dTimeCheck{1,1};
    end   
end

%% write lowest decile and their trips to csv and xls
tableVals = cell2table(peopleInPixelTrips);
writetable(tableVals, 'NorthCarolina_37129_LowestMI_PersonTrip.csv');
writetable(tableVals, 'NorthCarolina_37129_LowestMI_PersonTrip.xlsx');