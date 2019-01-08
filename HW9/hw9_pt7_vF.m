%% Part 7 Code OK

% Import aTaxiData, which has origin and destination x and y pixels
% along with the origin and destination times, in seconds.
aTaxiData = readtable('aTaxiDataHarris_v2.csv');

% Number of seconds in a day
num_secs = 86400;

% Total number of rows in Data
num_rows = height(aTaxiData);

% Time Interval is 60 seconds
time_int = 60;

%% Data Manipulation - OK

% changes: changed addvars to the other column adding method

% Adjust Data and round to integers
oTime_new = ceil((aTaxiData.oTime)/time_int);
dTime_new = ceil((aTaxiData.dTime)/time_int);

% Move trips that take place after 24 hours to
% the correct time within the established 24 hours
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

%% Time Data - OK

taxisByTime = zeros(num_secs/time_int, 1);

for i = 1:height(table(aTaxiData))
    depart_time = aTaxiData.oTime_new(i);
    arrive_time = aTaxiData.dTime_new(i);
    
    % If arrival time was moved to earlier
    if arrive_time < depart_time
       for j =  depart_time:1440
          taxisByTime(j) = taxisByTime(j) + 1; 
       end
       for j = 1:arrive_time
          taxisByTime(j) = taxisByTime(j) + 1; 
       end
    else
        % Trips that are not adjusted
        for j = depart_time:arrive_time
           taxisByTime(j) = taxisByTime(j) + 1; 
        end
    end
end

% Min Fleet size occurs when max number of aTaxis are traveling
% carrying passengers. 
minFleetSize = max(taxisByTime);
fprintf('Min Fleet Size is %d\n', minFleetSize);

%% Output Data into excel file

writetable(table(taxisByTime), 'NumberOfTaxisByTime_HarrisCounty_v2.xlsx');
