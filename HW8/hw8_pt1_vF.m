%% Reading in data
% takes ~2 mins, resizing table is not an issue

numOfFiles = 17;
dataTable = table;

% this part is for reading in the csv file
for i = 1:numOfFiles
   fileName = strcat('CSVFiles/FinalOriginPixel48201_', num2str(i), '.csv');
   data = readtable(fileName); 
   dataTable = vertcat(dataTable, data);
end
%% 
% get all unique pixels
uniquePixels = unique(dataTable(:, 9:10));
uniqueLength = height(uniquePixels);

%% Print Answers to Questions

% enter your home pixel info
% here i just picked something close to my home pixel of 208, -967
xHome = 202;
yHome = -988;

%%

disp('# of personTrips Originating from Your Home Pixel: ');
height(dataTable(dataTable.OXCoord == xHome & dataTable.OYCoord == yHome, :))

% # of Pixels that have at least one personTrip, i.e. # of unique pixels
disp('# of Unique Pixels: ');
uniqueLength

% # of PersonTrips From My County
disp('# of Person Trips from My County');
height(dataTable)

%% Counting # of originations per unique pixel
% maybe ~1.5 hrs to run?
countOrig = zeros(uniqueLength, 1);
for i = 1:uniqueLength
    currX = uniquePixels.OXCoord(i);
    currY = uniquePixels.OYCoord(i);
    countOrig(i) = height(dataTable(dataTable.OXCoord == currX & dataTable.OYCoord == currY, 1));
end
%% Set the countOrig as a column for unique pixels
uniquePixels.count = countOrig;
%% Output the file
writetable(uniquePixels, 'uniquePixels_aTaxiTrips_HarrisCountyFile_48201.xlsx');
%% Grab person trips from home pixel and pixel with the most
xPixelMost = 243;
yPixelMost = -998;

tripsFromHome = dataTable(dataTable.OXCoord == xHome & dataTable.OYCoord == yHome, :);
tripsFromMostPixel = dataTable(dataTable.OXCoord == xPixelMost & dataTable.OYCoord == yPixelMost, :);
%% Output the two files
writetable(tripsFromHome, 'tripsFromHome_aTaxiTrips_HarrisCountyFile_48201.xlsx');
writetable(tripsFromMostPixel, 'tripsFromMostPixel_aTaxiTrips_HarrisCountyFile_48201.xlsx');


%% --------------------NEW SECTION RUNS INDEPENDENTLY OF PREVIOUS CODE -----------------------------------------------
% NOT NECESSARY ANYMORE, JUST USE KEPLER
% meant to create bubble chart for most pixel/home pixel destinations
%% Read in data
%bubbleData = readtable('tripsFromMostPixel_aTaxiTrips_HarrisCountyFile_48201_BubblePlot.xlsx');

%% the variables of bubbleData.[SOMETHING] depends on what you named your column headers in excel!
%tripsOutOfCounty = bubbleData(bubbleData.InCounty_ == 0, :);
%tripsInCounty = bubbleData(bubbleData.InCounty_ == 1, :);

%xPixelOut = tripsOutOfCounty.dXPixel;
%yPixelOut = tripsOutOfCounty.dYPixel;
%numOut = tripsOutOfCounty.x_OfTripDestinations; % same here!

%xPixelIn = tripsInCounty.dXPixel;
%yPixelIn = tripsInCounty.dYPixel;
%numIn = tripsInCounty.x_OfTripDestinations;

%% Create the bubble plot
%color1 = [1 0 0];
%color2 = [0 1 0];
%legwords1 = 'Destination out of County';
%legwords2 = 'Destination in County';

%line(xPixelOut(1), yPixelOut(1), 'Color', color1, 'Visible', 'off');
%hold on;
%line(xPixelIn(1), yPixelIn(1), 'Color', color2, 'Visible', 'off');

%out = BubblePlot(xPixelOut, yPixelOut, numOut, color1);
%hold on;
%in = BubblePlot(xPixelIn, yPixelIn, numIn, color2);

%xlabel('dXPixel');
%ylabel('dYPixel');
%title('Destination of Trips Originating From My County');
%legend(legwords1, legwords2, 'Location', 'Best');
%set(gcf,'Color',[.8 .8 .8],'InvertHardCopy','off');

%% --------------------NEW SECTION RUNS INDEPENDENTLY OF PREVIOUS CODE -----------------------------------------------
% Analyzing the destinations of person trip originations from entire county
%% Reading in data
% takes ~2 mins, resizing table is not an issue

numOfFiles = 17;
dataTable = table;

% this part is for reading in the csv file
for i = 1:numOfFiles
   fileName = strcat('CSVFiles/FinalOriginPixel48201_', num2str(i), '.csv');
   data = readtable(fileName); 
   dataTable = vertcat(dataTable, data);
end

%% 
% get all unique origin pixels from county
countyPixels = unique(dataTable(:, 9:10));

% get all unique departure pixels
departures = unique(dataTable(:, 17:18));

%%
inCounty = ismember(departures.DXCoord, countyPixels.OXCoord) & ismember(departures.DYCoord, countyPixels.OYCoord);
departures.inCounty = inCounty;

%% Counting # of originations per unique pixel
% ~1 hour
uniqueLength = height(departures);
countDepart = zeros(uniqueLength, 1);
for i = 1:uniqueLength
    currX = departures.DXCoord(i);
    currY = departures.DYCoord(i);
    countDepart(i) = height(dataTable(dataTable.DXCoord == currX & dataTable.DYCoord == currY, 1));
end
%% Set the countOrig as a column for unique pixels
departures.count = countDepart;
%% Export departures to csv files
writetable(departures, 'allDepartures_aTaxiTrips_HarrisCountyFile_48201.csv');

%% Answers to Questions
disp('# of dPixels in County:');
sum(departures.inCounty)

disp('# of dPixels out of County:');
length(departures.inCounty) - sum(departures.inCounty)
%%
disp('% of PersonTripDestinations in County');
sumInCounty = 0;
sumOutCounty = 0;

for i = 1:uniqueLength
    if departures.inCounty(i) == 1
        sumInCounty = sumInCounty + departures.count(i);
    end
end

for i = 1:uniqueLength
    if departures.inCounty(i) == 0
        sumOutCounty = sumOutCounty + departures.count(i);
    end
end

sumInCounty / (sumInCounty + sumOutCounty)