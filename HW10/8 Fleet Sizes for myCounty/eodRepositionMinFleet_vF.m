%% Adapted from repositionEveryMinute

%% adjust these parameters before running
% csv with aTaxi data with the following headings:
%       columns 2,3 - oXPixel, oYPixel
%       column 4 - oTime (in seconds)
%       columns 6,7 - dXPixel, dYPixel
%       column 8 - dTime (in seconds)
final = readtable('harrisInputRepositioning_v2.csv'); 
% initialFleetSize = minFleetSize - # taxis on the road at 5am
initialFleetSize = 1439;
%% read in unique pixels
P = final(:, 2:3);
P2 = final(:, 6:7); 
P = unique(P, 'rows');
P = table(P.oXPixel, P.oYPixel, 'VariableNames', {'XPixel', 'YPixel'});
P2 = unique(P2, 'rows');
P2 = table(P2.dXPixel, P2.dYPixel, 'VariableNames', {'XPixel', 'YPixel'});
combinedP = [P;P2];
combinedP = unique(combinedP, 'rows');
scale = length(combinedP.XPixel);
emptyTrip = scale*scale;
%% compute costs/distances
for i = 1:scale
    for j = 1:scale
        idxs(j + scale*(i-1), 1) = i; 
        idxs(j + scale*(i-1), 2) = j;  
    end 
end 
cost = hypot(combinedP.XPixel(idxs(:,1)) - combinedP.XPixel(idxs(:,2)), ...
              combinedP.YPixel(idxs(:,1)) - combinedP.YPixel(idxs(:,2))); 
%% compute inequality A matrix
for i = 1:scale
    in = transpose(idxs(:,2) == i); 
    out = transpose(idxs(:,1) == i);  
    Aeq(i, :) = (in-out);
end 


%% Jasmine/Stewart Code

% Import aTaxiData, which has origin and destination x and y pixels
% along with the origin and destination times, in seconds.
aTaxiData = readtable('aTaxiDataHarris_v2.csv');

% Number of seconds in a day
num_secs = 86400;

% Total number of rows in Data
num_rows = height(aTaxiData);

%% Establish Time Interval and adjust times OK

% David Changes - changed 'addvars' command since 2017b version of matlab
% doesn't have that command.

time_int = 60; % 60 seconds in one minute

start = 18000; % Start time is 5am

% Adjust Data and round to integers
oTime_new = ceil((aTaxiData.oTime - start)/time_int);
dTime_new = ceil((aTaxiData.dTime - start)/time_int);

% Since we start at 5AM, we must move trips that are before
% 5AM to the end of the data by adding 24 hours
for i = 1:length(oTime_new)
    % Origin times 
    if oTime_new(i) < 0
        oTime_new(i) = oTime_new(i) + num_secs/time_int;
    end
    
    % Destination Times
    if dTime_new(i) < 0
        dTime_new(i) = dTime_new(i) + num_secs/time_int;
    end
end

% Move trips that take place after 24 hours to
% the correct time within the established 24 hours
% (Not sure if necessary, but will not negatively affect data)
for i = 1:length(oTime_new)
    % Origin times 
    if oTime_new(i) > num_secs/time_int
        oTime_new(i) = oTime_new(i) - num_secs/time_int;
    end
    
    % Destination Times
    if dTime_new(i) > num_secs/time_int
        dTime_new(i) = dTime_new(i) - num_secs/time_int;
    end
end

% Add adjusted times to data table
aTaxiData.oTime_new = oTime_new;
aTaxiData.dTime_new = dTime_new;

%% Extract Origin and Destination Pixels OK

originData = [aTaxiData(:, 1:2) aTaxiData(:, 7)];
destData = [aTaxiData(:, 4:5) aTaxiData(:, 8)];

% Get all Unique Pixels
uniqueOPixels = unique(originData(:, 1:2));
uniqueDPixels = unique(destData(:, 1:2));

%% Assign an ID to each unique pixel OK

all_unique = unique(horzcat(vertcat(uniqueOPixels.OXPixel, uniqueDPixels.dXPixel), vertcat(uniqueOPixels.OYPixel, uniqueDPixels.dYPixel)), 'rows');

ID_all = ones(height(table(all_unique)), 1);
for i = 1:height(table(all_unique))
    ID_all(i) = i;
end

% Add IDs to unique Pixel array
all_unique = horzcat(all_unique, ID_all);

%% Add pixel labels to Origin and Destination Data OK

% David Changes - changed addvars command for 2017b version

%num_unique_oPixels = height(uniqueOPixels);
%num_unique_dPixels = height(uniqueDPixels);

% Create ID arrays
%origin_ID = ones(num_rows, 1);
%dest_ID = ones(num_unique_dPixels, 1);
origin_ID = ones(num_rows, 1);
dest_ID = ones(num_rows, 1);

X = array2table(all_unique);

% Populate Origin ID Array
for i = 1:num_rows
    xPixel = originData.OXPixel(i);
    yPixel = originData.OYPixel(i);
    ID = X(X.all_unique1 == xPixel & X.all_unique2 == yPixel, 3);
    origin_ID(i) = ID.all_unique3;
end

% Populate Destination ID Array
for i = 1:num_rows
    xPixel = destData.dXPixel(i);
    yPixel = destData.dYPixel(i);
    ID = X(X.all_unique1 == xPixel & X.all_unique2 == yPixel, 3);
    dest_ID(i) = ID.all_unique3;
end

% Assign to pixel values
%uniqueOPixels = addvars(uniqueOPixels, origin_ID);
%uniqueDPixels = addvars(uniqueDPixels, dest_ID);
originData.origin_ID = origin_ID;
destData.dest_ID = dest_ID;

%% Create matrix for taxi quantities OK

numTaxi = zeros(height(table(all_unique)), num_secs/time_int);
prevVal = zeros(height(table(all_unique)), 1); %changed
%% Populate numTaxi matrix - OK

% changes: Split the two loops

% For minute 1, since there are no existing taxis

% Arriving Taxi
pixel_dest_byTime = destData(destData.dTime_new == 1, 4);
for j = 1:height(pixel_dest_byTime)
    numTaxi(pixel_dest_byTime.dest_ID(j), 1) = numTaxi(pixel_dest_byTime.dest_ID(j), 1) + 1;
    prevVal(pixel_dest_byTime.dest_ID(j), 1) = numTaxi(pixel_dest_byTime.dest_ID(j), 1); % changed
end
%Departing Taxi
pixel_orig_byTime = originData(originData.oTime_new == 1, 4);
for j = 1:height(pixel_orig_byTime)
    numTaxi(pixel_orig_byTime.origin_ID(j), 1) = numTaxi(pixel_orig_byTime.origin_ID(j), 1) - 1;
    prevVal(pixel_orig_byTime.origin_ID(j), 1) = numTaxi(pixel_orig_byTime.origin_ID(j), 1); % changed
end

%% - OK

% Iterate through time, adding one if a taxi arrives at that pixel,
% and subtracting one if a taxi originates from that pixel. 
for i = (2:(num_secs/time_int - 1))
    % Arriving Taxi
    pixel_dest_byTime = destData(destData.dTime_new == i, 4);
    for j = 1:height(pixel_dest_byTime)
        numTaxi(pixel_dest_byTime.dest_ID(j), i) = prevVal(pixel_dest_byTime.dest_ID(j), 1) + 1; %changed
        prevVal(pixel_dest_byTime.dest_ID(j), 1) = numTaxi(pixel_dest_byTime.dest_ID(j), i); % changed
    end
    % Departing Taxi
    pixel_orig_byTime = originData(originData.oTime_new == i, 4);
    for j = 1:height(pixel_orig_byTime)
        numTaxi(pixel_orig_byTime.origin_ID(j), i) = prevVal(pixel_orig_byTime.origin_ID(j), 1) - 1; %changed
        prevVal(pixel_orig_byTime.origin_ID(j), 1) = numTaxi(pixel_orig_byTime.origin_ID(j), i); % changed
    end
end
%% MAJOR CHANGE FOR V2

numTaxi(:, 1439) = prevVal(:, 1);
%% Find Max Deficit for each pixel

% changes: went from "maxFleetSize =
% height(table(numTaxi))*sum(maxDeficit);" to just "sum(maxDeficit);"

maxDeficit = zeros(height(table(numTaxi)), 1);
eod = zeros(height(table(numTaxi)), 1);

% Max Deficit for each pixel
for i = 1:height(table(numTaxi))
    maxDeficit(i) = -min(numTaxi(i, :));
end

% Max fleet size is found by having the sum over all pixels of 
% max deficit at each pixel.
maxFleetSize = sum(maxDeficit);
%fprintf('Max Fleet Size is %d\n', maxFleetSize);

for i = 1:height(table(numTaxi))
    x = numTaxi(i, 1439); % this is the eod value since numTaxi is cumulative over the mins
    if (maxDeficit(i) > 0) %if max deficit is positive that means that there was a deficit at 
        %some point, therefore, the eod value has to be increased by the max deficit value 
        %as aTaxis would've been positioned there at 5AM
        eod(i) = x + round((maxDeficit(i) / maxFleetSize) * initialFleetSize); 
    else
        eod(i) = x;
    end
end

%% Output Data for the Bubble Chart

% changed the assignment of -1 and +1 for deficit/surplus

% Initialize array
bubbleData = zeros(length(maxDeficit), 4);

for i = 1:length(bubbleData)
    % Pixel Values
   bubbleData(i, 1:2) = all_unique(i, 1:2);
   % Max Deficit value
   bubbleData(i, 3) = maxDeficit(i);
   % If there is a deficit, we use boolean -1 to designate
   % col 5 is for net supply/demand
   if maxDeficit(i) > 0
       % Boolean indicating whether it is positive or negative
       bubbleData(i, 4) = -1;
       bubbleData(i, 5) = round((maxDeficit(i) / maxFleetSize) * initialFleetSize) - eod(i); % positive if surplus, negative if demand

   % otherwise, we have a surplus (including max deficit scores of 0). We
   % use +1 to designate
   else 
       bubbleData(i, 4) = 1;
       bubbleData(i, 5) = -eod(i); % always surplus or zero
   end
end


%%
fprintf('Sum of Net Supply is %d\n', sum(bubbleData(bubbleData(:, 5) > 0, 5)));
[sol, fval] = intlinprog(cost, emptyTrip, -Aeq, bubbleData(:, 5), [], [], zeros(emptyTrip, 1));
fprintf('EoD Empty aTaxiCartesianMiles (Min Fleet Size: %d', fval);