%% hw10_aTaxiTripsFromMyPixel

%% Reading in data
trips = readtable('harrisAllaTaxiInfo.csv');

%% Enter myPixel

myXPixel = 224;
myYPixel = -999;

%% Cleaning data...

myPixelTrips = trips(trips.oXPixel == myXPixel & trips.oYPixel == myYPixel, :);

%% output answers

disp('aTaxi Departures/Day from MyPixel')
height(myPixelTrips)

disp('PersonTripsServed...')
sum(myPixelTrips.departureOccupancy)

disp('ADO')
mean(myPixelTrips.departureOccupancy)

disp('PersonTripCartesianTripMiles')
sum(myPixelTrips.personTripMiles)

disp('aTaxi Cartesian Trip Miles')
sum(myPixelTrips.aTaxiTripMiles)

disp('AVO')
sum(myPixelTrips.personTripMiles) / sum(myPixelTrips.aTaxiTripMiles)