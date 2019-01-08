%% Part 1-a-b-i-1 code

%% Reading in a state's personTrips.

pixelSet = readtable('UniquePixelSet.csv'); %make sure you are in the same direc when reading 
%% Read in all trips from your geofenced area

allPersonTrips = readtable('FinalOriginPixel48201_3.csv');
%% Answers to Question 2

disp('# of personTrips Originating from Geo-Fenced Area: ');
height(allPersonTrips)
uniquePixels = [pixelSet.xPixel pixelSet.yPixel];
%%

disp('# of personTrips Originating and Terminating from Geo-Fenced Area: ');
tripsOrigandDestArray = [];
for i = 1:height(allPersonTrips)
   currDXCoord = allPersonTrips.DXCoord(i);
   currDYCoord = allPersonTrips.DYCoord(i);
   currLoc = [currDXCoord currDYCoord];
   if (ismember(currLoc, uniquePixels, 'rows'))
       tripsOrigandDestArray = [tripsOrigandDestArray, i];
   end
end
%tripsOrigandDest = allPersonTrips(ismember(allPersonTrips.DXCoord, pixelSet.xPixel) & ismember(allPersonTrips.DYCoord, pixelSet.yPixel), :);
%%
length(tripsOrigandDestArray)
tableTemp = allPersonTrips(tripsOrigandDestArray, :);

%%
writetable(allPersonTrips, 'tripsOrig_aTaxiTrips_HarrisCountyFile_48201.xlsx');
writetable(tableTemp, 'tripsOrigandDest_aTaxiTrips_HarrisCountyFile_48201.xlsx');

