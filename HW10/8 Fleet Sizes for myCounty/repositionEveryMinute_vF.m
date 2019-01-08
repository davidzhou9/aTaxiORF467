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
%% compute net supply demand at each pixel at each minute
check = [1:1440];
check = transpose(check);
byPixel = zeros(1440, scale); 
combinedP.maxDeficit = zeros(scale,1);

for i = 1:scale
    
    x = combinedP.XPixel(i);
    y = combinedP.YPixel(i); 
    
    fromRows = final.oXPixel == x & final.oYPixel == y; 
    from = final(fromRows, :); 
    
    toRows = final.dXPixel == x & final.dYPixel == y; 
    to = final(toRows, :);

    from.minute = floor(from.oTime./60);
    from.minute(from.minute > 1440) = from.minute(from.minute > 1440) - 1440;
    fromminutes = tabulate(from.minute);
    toAdd = setdiff(check, fromminutes(:,1));
    for j = 1:length(toAdd)
        fromminutes(length(fromminutes(:,1)) +1, 1) = toAdd(j);
    end 
    if fromminutes(1,1) == 0
        fromminutes(fromminutes(:,1) == 1440, :) = fromminutes(fromminutes(:,1) == 1440, :) + fromminutes(1,:);
        fromminutes = fromminutes(2:length(fromminutes(:,1)), :);
    end     
    fromminutes(fromminutes(:,1) < 300, 1) = fromminutes(fromminutes(:,1) < 300, 1) + 1440; 
    fromminutes = sortrows(fromminutes, 1);
    
    if sum(fromRows) ~= 0
        fromminutes(1,4) = fromminutes(1,2); 
        for k = 2:length(fromminutes(:,1))
            fromminutes(k,4) = fromminutes(k,2) + fromminutes(k-1,4);
        end
    else 
        fromminutes(:,2) = zeros(length(fromminutes(:,1)),1);
        fromminutes(:,3) = zeros(length(fromminutes(:,1)),1);
        fromminutes(:,4) = zeros(length(fromminutes(:,1)),1); 
    end 

    to.minute = floor(to.dTime./60);
    to.minute(to.minute > 1440) = to.minute(to.minute > 1440) - 1440; 
    tominutes = tabulate(to.minute);
    toAdd = setdiff(check, tominutes(:,1));
    for l = 1:length(toAdd)
        tominutes(length(tominutes(:,1)) + 1, 1) = toAdd(l);
    end 
    if tominutes(1,1) == 0
        tominutes(tominutes(:,1) == 1440, :) = tominutes(tominutes(:,1) == 1440, :) + tominutes(1,:);
        tominutes = tominutes(2:length(tominutes(:,1)), :);
    end 
    tominutes(tominutes(:,1) < 300) = tominutes(tominutes(:,1) < 300) + 1440; 
    tominutes = sortrows(tominutes, 1);


    if sum(toRows) ~= 0
        tominutes(1,4) = tominutes(1,2); 
        for m = 2:length(tominutes(:,1))
            tominutes(m,4) = tominutes(m,2) + tominutes(m-1,4);
        end 
    else 
        tominutes(:,2) = zeros(length(tominutes(:,1)),1);
        tominutes(:,3) = zeros(length(tominutes(:,1)),1);
        tominutes(:,4) = zeros(length(tominutes(:,1)),1); 
    end 

    fromminutes(fromminutes(:,1) > 1440) = fromminutes(fromminutes(:,1) > 1440) - 1440; 
    tominutes(tominutes(:,1) > 1440) = tominutes(tominutes(:,1) > 1440) - 1440; 
    fromminutes = sortrows(fromminutes, 1);
    tominutes = sortrows(tominutes,1); 
    
    netflow = tominutes(:,2) - fromminutes(:,2);
    combinedP.maxDeficit(i) = min(netflow);
    byPixel(:, i) = netflow; 
end
%% initialize taxis at 5:00am 
combinedP.taxisat5 = -min(0, combinedP.maxDeficit);
minVector = zeros(1,scale); 
minVector(1, :) = min(min(byPixel(300, :)),0);
positions = abs(minVector); 
extraTaxis = initialFleetSize - sum(positions); 
normalize = combinedP.taxisat5 * extraTaxis./sum(combinedP.taxisat5);
distribute = floor(normalize); 
remainder = normalize - distribute; 
while sum(distribute) ~= extraTaxis
    [maxValue, idx] = max(remainder); 
    distribute(idx) = distribute(idx) + 1; 
    remainder(idx) = 0; 
end 
positions = positions + transpose(distribute); 
fiveam = byPixel(300,:);
byPixel(300, :) = fiveam + positions; 
% vectors to store data on repositioning 
repositionedTaxis = zeros(1440, 1);
repositionedMiles = zeros(1440, 1); 
%% reposition every minute from 5:00am-midnight
for j = 301:1440
    supply = zeros(1,scale); 
    demand = zeros(1,scale); 
    byPixel(j, :) = byPixel(j, :) + byPixel(j-1, :);
    for i = 1:scale
        minVector(1, i) = min(byPixel(j, i), 0);
        minVector(1, i) = abs(minVector(1,i)); 
        supply(1, i) = max(0, byPixel(j, i)); 
        demand(1, i) = minVector(1, i); 
    end 
    
    beq = transpose(supply - demand);
    if min(beq) < 0
        [sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(emptyTrip,1));
        repositionedMiles(j, 1) = fval;
        finalsol = zeros(scale, scale); 
        for i = 1:scale
            for k = 1:scale
                finalsol(i, k) = sol(scale*(i-1) + k); 
            end 
        end 
        for i = 1:scale
           newtaxis = sum(transpose(finalsol(:, i)));
           leavingtaxis = sum(finalsol(i, :)); 
           byPixel(j, i) = byPixel(j, i) + newtaxis - leavingtaxis;
        end 
        repositionedTaxis(j, 1) = sum(demand);
    end 
end 
%% reposition 0:01AM - 4:59AM
for j = 1:299
    supply = zeros(1,scale); 
    demand = zeros(1,scale); 
    if j == 1
        byPixel(j, :) = byPixel(j, :) + byPixel(1440, :);
    else 
        byPixel(j, :) = byPixel(j, :) + byPixel(j-1, :);
    end 
    for i = 1:scale
        minVector(1, i) = min(byPixel(j, i), 0);
        minVector(1, i) = abs(minVector(1,i)); 
        supply(1, i) = max(0, byPixel(j, i)); 
        demand(1, i) = minVector(1, i); 
    end 
    
    beq = transpose(supply - demand);
    if min(beq) < 0
        [sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(emptyTrip,1));
        repositionedMiles(j, 1) = fval;
        finalsol = zeros(scale, scale); 
        for i = 1:scale
            for k = 1:scale
                finalsol(i, k) = sol(scale*(i-1) + k); 
            end 
        end 
        for i = 1:scale
           newtaxis = sum(transpose(finalsol(:, i)));
           leavingtaxis = sum(finalsol(i, :)); 
           byPixel(j, i) = byPixel(j, i) + newtaxis - leavingtaxis;
        end 
    repositionedTaxis(j, 1) = sum(demand);  
    end 
end 
%% EoD repositioning (4:59am - 5:00am) 
beq = transpose(byPixel(299, :) - byPixel(300,:) + fiveam);
[sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(emptyTrip,1));
demand = abs(min(0, beq)); 
repositionedTaxis(300, 1) = sum(demand);
repositionedMiles(300, 1) = fval;  
%% write results to csv file
results = table(fromminutes(:,1), repositionedMiles, repositionedTaxis);
writetable(results, 'RepositionEveryMinuteHarris_v3.csv');