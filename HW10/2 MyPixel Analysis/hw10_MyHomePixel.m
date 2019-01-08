%% hw10_MyHomePixel Code

%% Read in all trips from "...Module1NN2ndRun"

allIndividuals = readtable('Texas48201Module1NN2ndRun.csv');

%% Convert lat/long home to xPixel, yPixel
len = height(allIndividuals);
xPix = zeros(len, 1);
yPix = zeros(len, 1);

for row = 1:len
    lat = allIndividuals.Latitude(row);
    long = allIndividuals.Longitude(row);
    
    xPix(row) = floor(138.348*(long+97.5)*cos(lat * pi / 180));
    yPix(row) = floor(138.348*(lat - 37));
    
end

allIndividuals.XPixel = xPix;
allIndividuals.YPixel = yPix;
%% Get all individuals that live in the home Pixel

% enter your home pixel coordinates here
homeXPixel = 202;
homeYPixel = -988;

homePixelPpl = allIndividuals(allIndividuals.XPixel == homeXPixel & allIndividuals.YPixel == homeYPixel, :);
%% Ouput answers

disp('My County Home Pixel Population: ');
height(homePixelPpl)

uniqueHH = unique(homePixelPpl.HHID);
disp('My County Max Pixel HH Number: ');
length(uniqueHH)