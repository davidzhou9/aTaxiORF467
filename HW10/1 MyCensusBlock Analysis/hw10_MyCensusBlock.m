%% hw10_MyCensusBlock Code

%% Reading in personIDs from my census track/block

personIDSet = readtable('PersonIDSDavid.xlsx'); %make sure you are in the same direc when reading 
%% Read in all trips from "...Module6NN1st Run"

allPersonTrips = readtable('Texas_48201_Module6NN1stRun.csv');

%%
%disp('# of personTrips Originating from Geo-Fenced Area: ');
%height(allPersonTrips)

%disp('# of personTrips Originating and Terminating from Geo-Fenced Area: ');
%tripsOrigandDest = allPersonTrips(ismember(allPersonTrips.DXCoord, pixelSet.xPixel) & ismember(allPersonTrips.DYCoord, pixelSet.yPixel), :);
%height(tripsOrigandDest)
%% Get all persontrips where the person lives in my census block
cleanedTrips = allPersonTrips(ismember(allPersonTrips.PersonIDNumber, personIDSet.PersonIDNumber), :);

%%
outputIndex = 2;
% # of trips x max of 7 trips + 1 for column headers = max number of rows with 10 column fields
peopleInPixelTrips = cell(40000, 10);
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

%%
tableVals = cell2table(peopleInPixelTrips);
writetable(tableVals, 'FileOfPeopleLivingInMyCensusBlock.xlsx');