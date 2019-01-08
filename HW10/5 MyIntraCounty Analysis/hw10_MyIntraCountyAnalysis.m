%% hw10_MyIntraCountyAnalysis Code

%% Reading in data
% takes ~2 mins, resizing table is not an issue
% taken from HW8 code

numOfFiles = 17;
allTrips = table;

% this part is for reading in the csv file
for i = 1:numOfFiles
   fileName = strcat('CSVFiles/FinalOriginPixel48201_', num2str(i), '.csv');
   data = readtable(fileName); 
   allTrips = vertcat(allTrips, data);
end

%% Find all county pixels
% get all unique origin pixels from county
tempMat = [allTrips.OXCoord allTrips.OYCoord];
countyPixels = unique(tempMat, 'rows');

%% Get all trips that are intracounty trips
tripDCoords = [allTrips.DXCoord allTrips.DYCoord];
%%
inCountyTrips = allTrips(ismember(tripDCoords, countyPixels, 'rows'),:);


%% Display Answers
numInCountyTrips = height(inCountyTrips);
disp('IntraCountyPersonTrips: ');
numInCountyTrips

disp('Average PersonTripGCD: ');
mean(inCountyTrips.GCDistance)


%% Count % of Trips in a certain GCDist range

LessThanDec = 0;
BetweenDecand3 = 0;
Between3and100 = 0;
Greaterthan100 = 0;

for i = 1:numInCountyTrips
   tempGCDist = inCountyTrips.GCDistance(i);
   
   if (tempGCDist < 0.707)
       LessThanDec = LessThanDec + 1;
   elseif (tempGCDist >= 0.707 && tempGCDist < 3)
       BetweenDecand3 = BetweenDecand3 + 1;
   elseif (tempGCDist >= 3 && tempGCDist < 100)
       Between3and100 = Between3and100 + 1;
   else
       Greaterthan100 = Greaterthan100 + 1;
   end
end

%% Out range %'s

disp('% GCD < 0.707: ');
LessThanDec / numInCountyTrips

disp('% 0.707 <= GCD < 3: ');
BetweenDecand3 / numInCountyTrips

disp('% 3 <= GCD < 100: ');
Between3and100 / numInCountyTrips

disp('% 100 <= GCD: ');
Greaterthan100 / numInCountyTrips

