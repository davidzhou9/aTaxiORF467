%% PART 2 CODE

%% Reading in all aTaxi departures

aTaxiTrips = readtable('aTaxiDeparturePt4_v2.csv'); %make sure you are in the same direc when reading 
%% Part A: Get this from the RideShareAnalysis file
maxXPixel = 227;
maxYPixel = -1000;

%% Part B: Getting all aTaxi trips that originate from the max pixel and finding lat/long of destinations
origMaxPixel = aTaxiTrips(aTaxiTrips.OXPixel == maxXPixel & aTaxiTrips.OYPixel == maxYPixel, :);
%% Part C: get all aTaxi trips that end up in the max pixel and finding lat/long of destinations
destMaxPixel = aTaxiTrips(aTaxiTrips.dXPixel == maxXPixel & aTaxiTrips.dYPixel == maxYPixel, :);

%% Output files
writetable(origMaxPixel, 'origMaxPixelAnalysis_v2.xlsx');
writetable(destMaxPixel, 'destMaxPixelAnalysis_v3.xlsx');
