%% hw10_aTaxiTripsFromMyMaxPixel

%% Reading in data
trips = readtable('harrisAllaTaxiInfo.csv');

%% Enter myMaxPixel

myMaxXPixel = 227;
myMaxYPixel = -1000;

%% Cleaning data...

myMaxPixelTrips = trips(trips.oXPixel == myMaxXPixel & trips.oYPixel == myMaxYPixel, :);

%% output answers

disp('aTaxi Departures/Day from MyPixel')
height(myMaxPixelTrips)

disp('PersonTripsServed...')
sum(myMaxPixelTrips.departureOccupancy)

disp('ADO')
mean(myMaxPixelTrips.departureOccupancy)

disp('PersonTripCartesianTripMiles')
sum(myMaxPixelTrips.personTripMiles)

disp('aTaxi Cartesian Trip Miles')
sum(myMaxPixelTrips.aTaxiTripMiles)

disp('AVO')
sum(myMaxPixelTrips.personTripMiles) / sum(myMaxPixelTrips.aTaxiTripMiles)