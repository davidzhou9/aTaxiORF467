%% hw10_MyCountyandCountyPersonTripsAnalysis Code

%% Read in all trips from "...Module1NN2ndRun"

allIndividuals = readtable('Texas48201Module1NN2ndRun.csv');

%% Ouput answers

disp('My County Population: ');
height(allIndividuals)

uniqueHH = unique(allIndividuals.HHID);
disp('My County HH Number: ');
length(uniqueHH)

%% Now, we do the analysis for the "My County PersonTrips" part
% Need to calculate average PersonTripGCD and % of trips in given GCD range

%% Reading in data
% takes ~2 mins, resizing table is not an issue
% taken from HW8 code

numOfFiles = 17;
dataTable = table;

% this part is for reading in the csv file
for i = 1:numOfFiles
   fileName = strcat('CSVFiles/FinalOriginPixel48201_', num2str(i), '.csv');
   data = readtable(fileName); 
   dataTable = vertcat(dataTable, data);
end

%% Ouput PersonTripGCDist
avgPersonTripGCD = mean(dataTable.GCDistance);
disp('My County PersonTrips: Average PersonTripGCD: ')
avgPersonTripGCD

%% Count % of Trips in a certain GCDist range

LessThanDec = 0;
BetweenDecand3 = 0;
Between3and100 = 0;
Greaterthan100 = 0;
numTrips = height(dataTable);

for i = 1:height(dataTable)
   tempGCDist = dataTable.GCDistance(i);
   
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
LessThanDec / numTrips

disp('% 0.707 <= GCD < 3: ');
BetweenDecand3 / numTrips

disp('% 3 <= GCD < 100: ');
Between3and100 / numTrips

disp('% 100 <= GCD: ');
Greaterthan100 / numTrips


