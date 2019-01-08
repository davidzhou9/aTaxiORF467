%% part a

% this part is for reading in the csv file and extracting the
% block and tract corresponding to your house
data = readtable('Massachusetts25017Module1NN2ndRun.csv');
dataMatrix = table2array(data);

%%

ind1 = dataMatrix(:,4) == 363103 &  dataMatrix(:,5) == 1019;
trackBlockData = dataMatrix(ind1, :);

xlswrite('MABlockTrackCleaned', trackBlockData)

%% part b
% this part is for selecting the trips that correspond to the
% HHID that one is interested in studying

dataTrips = readtable('Texas_48201_Module6NN1stRun.csv');
cleaned = dataTrips(dataTrips.HHID == 5241985, :);
%writetable(cleaned, 'TripsTexas48201Cleaned.csv');


%% part c
% this part is for pixelating all rows of 2nd run, finding all census
% tracks that pixelate to your home pixel and then extracting all records
% that pixelate to the home pixel

data = readtable('Texas48201Module1NN2ndRun.csv');
dataMatrix = table2array(data);

%%
% enter your HHID's x and y pixel here
homeXPixel = 208;
homeYPixel = -967;

convertedXPixel = dataMatrix(:,8);
convertedYPixel = dataMatrix(:,9);

% loop converts all lat, longs to xPixel, yPixel for 2nd run data
for r = 1:length(convertedXPixel)
   tempLat = convertedXPixel(r);
   tempLong = convertedYPixel(r);
   
   xPixel = floor(138.348 * (tempLong + 97.5) * cos(tempLat * pi / 180));
   yPixel = floor(138.348 * (tempLat - 37));
   
   convertedXPixel(r) = xPixel;
   convertedYPixel(r) = yPixel;
end

% find the indices of the records in 2nd run that pixelate to your home
% pixel
indHomePixel = convertedXPixel(:,:) == homeXPixel &  convertedYPixel(:,:) == homeYPixel;
dataFromHomePixel = dataMatrix(indHomePixel, :);
% grab only the HHID's that correspond to the ones that pixelate to same
% home pixel
hhidMapToHomePixel = dataFromHomePixel(:, 6);

%% read in 1st run data
dataTripsPixel = readtable('Texas_48201_Module6NN1stRun.csv');


%%
cleanedTrips = dataTripsPixel(ismember(dataTripsPixel.HHID, hhidMapToHomePixel),:);
%%

outputIndex = 2;
% # of trips x max of 7 trips + 1 for column headers = max number of rows with 10 column fields
peopleInPixelTrips = cell(18380, 10); %19435 comes from examining my matrix, will vary for others
step = 9; % column of next node name is 9 cols over

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

%% write to csv and xls
tableVals = cell2table(peopleInPixelTrips);
writetable(tableVals, 'NN_FileOfPeopleLivingInMyPixel208,-967.csv');
writetable(tableVals, 'FileOfPeopleLivingInMyPixel208,-967.xlsx');

