%% 
final = readtable('harrisInputRepositioning_v2.csv');

P = final(:, 2:3);
P2 = final(:, 6:7); 
P = unique(P, 'rows');
P = table(P.oXPixel, P.oYPixel, 'VariableNames', {'XPixel', 'YPixel'});
P2 = unique(P2, 'rows');
P2 = table(P2.dXPixel, P2.dYPixel, 'VariableNames', {'XPixel', 'YPixel'});
minFleetSize = 1439;
%
combinedP = [P;P2];
combinedP = unique(combinedP, 'rows');
combinedP.maxDeficit = zeros(length(combinedP.XPixel),1);
combinedP.totalIn = zeros(length(combinedP.XPixel),1);
combinedP.totalOut = zeros(length(combinedP.XPixel),1);
% create variables
number = length(combinedP.XPixel);
number = number*number;
emptyTrip = number; 
% create costs
scale = sqrt(number);
for i = 1:length(combinedP.XPixel)
    for j = 1:length(combinedP.YPixel)
        idxs(j + scale*(i-1), 1) = i; 
        idxs(j + scale*(i-1), 2) = j;  
    end 
end 
dist = hypot(combinedP.XPixel(idxs(:,1)) - combinedP.XPixel(idxs(:,2)), ...
              combinedP.YPixel(idxs(:,1)) - combinedP.YPixel(idxs(:,2)));
cost = dist; 
% 
for i = 1:length(combinedP.XPixel)
    in = transpose(idxs(:,2) == i); 
    out = transpose(idxs(:,1) == i);  
    Aeq(i, :) = (in-out);
end 

check = [1:1440];
check = transpose(check);
byPixel = zeros(1440, length(combinedP.XPixel)); 
%
for i = 1:length(combinedP.XPixel)
    
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
    combinedP.totalIn(i) = length(to.minute);
    combinedP.totalOut(i) = length(from.minute);
    byPixel(:, i) = netflow; 
end

combinedP.taxisat5 = -min(0, combinedP.maxDeficit);
netsupplydemand = combinedP.totalIn - combinedP.totalOut; 
combinedP.taxisat4 = combinedP.taxisat5 + netsupplydemand; 
index = netsupplydemand > 0; 
combinedP.netSupply(index) = netsupplydemand(index); 
index2 = netsupplydemand < 0; 
combinedP.netDemand(index2) = abs(netsupplydemand(index2)); 
%% initialize taxis; 
minVector = zeros(1,scale); 
for i = 1:scale
    minVector(1, i) = min(min(byPixel(300:305, i)),0); %changed from 359 to 305
end 
positions = abs(minVector); 
extraTaxis = minFleetSize - sum(positions); 
normalize = combinedP.taxisat5 * extraTaxis./sum(combinedP.taxisat5);
distribute = floor(normalize); 
remainder = normalize - distribute; 
while sum(distribute) ~= extraTaxis
    [maxValue, idx] = max(remainder); 
    distribute(idx) = distribute(idx) + 1; 
    remainder(idx) = 0; 
end 
positions = positions + transpose(distribute); 
byPixel(300, :) = byPixel(300, :) + positions; 
%for i = 1:5 %changed from 1:59 to 1:5
%    byPixel(300 + i, :) = byPixel(300 + i-1, :) + positions;
%end 
%%
repositionedTaxis = zeros(240, 1); %changed from 24 to 240
repositionedMiles = zeros(240, 1); %changed from 24 to 240
maxUnserved = 100000000;
%% reposition hourly
%for j = 52:240 % changed loop iterations
for j = 51:240
    supply = zeros(1,scale);
    demand = zeros(1,scale);
    if j == 1
        byPixel(1440, :) = byPixel(1440, :) + byPixel(1439, :);
        byPixel(1,:) = byPixel(1, :) + byPixel(1440, :); 
        for i = 2:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) = min(min(byPixel(1:5, i)), byPixel(1440, i));
        %    minVector(1, i) = min(minVector(1, i),0);
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel(1439, i));
        %    demand(1, i) = minVector(1, i);
        %end
    elseif j == 51
        for i = 1:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) =  min(min(byPixel((j-1)*60:(j*60-1), i)), 0);
        %    minVector(1, i) = max(0, byPixel((j-1)*6, i) - min(byPixel((j-1)*6:(j*6-1), i)));
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel((j-1)*6-1, i));
        %    demand(1, i) = minVector(1, i);
        %end
    else
        for i = 0:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) =  min(min(byPixel((j-1)*60:(j*60-1), i)), 0);
        %    minVector(1, i) = max(0, byPixel((j-1)*6, i) - min(byPixel((j-1)*6:(j*6-1), i)));
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel((j-1)*6-1, i));
        %    demand(1, i) = minVector(1, i);
        %end
    end
    
    %beq = transpose(supply - demand);
    beq = transpose(byPixel(j*6 - 1, :));
    
    if min(beq) < 0
        [sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(number,1));
        if j == 1
            repositionedMiles(240, 1) = fval;
        else
            repositionedMiles(j-1, 1) = fval;
        end
        finalsol = zeros(scale, scale);
        for i = 1:length(combinedP.XPixel)
            for k = 1:length(combinedP.YPixel)
                finalsol(i, k) = sol(scale*(i-1) + k);
            end
        end
        for i = 1:scale
            newtaxis = sum(transpose(finalsol(:, i)));
            leavingtaxis = sum(finalsol(i, :));
            if j == 1
                byPixel(1440, i) = byPixel(1440, i) + newtaxis - leavingtaxis;
                byPixel(1:5, i) = byPixel(1:5, i) + newtaxis - leavingtaxis;
            elseif j == 51
                byPixel((j-1)*6 + 1:j*6-1, i) = byPixel((j-1)*6 + 1:j*6-1, i) + newtaxis - leavingtaxis;
            else
                byPixel((j-1)*6:j*6-1, i) = byPixel((j-1)*6:j*6-1, i) + newtaxis - leavingtaxis;
            end
        end
    else
        if j == 1
            repositionedMiles(240, 1) = 0;
        else
            repositionedMiles(j-1, 1) = 0;
        end
    end
    if j == 1
        repositionedTaxis(240, 1) = -sum(beq(beq < 0));
    else
         repositionedTaxis(j-1, 1) = -sum(beq(beq < 0));
    end
end 
%% reposition hourly
for j = 1:50
    supply = zeros(1,scale);
    demand = zeros(1,scale);
    if j == 1
        byPixel(1440, :) = byPixel(1440, :) + byPixel(1439, :);
        byPixel(1,:) = byPixel(1, :) + byPixel(1440, :); 
        for i = 2:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) = min(min(byPixel(1:5, i)), byPixel(1440, i));
        %    minVector(1, i) = min(minVector(1, i),0);
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel(1439, i));
        %    demand(1, i) = minVector(1, i);
        %end
    elseif j == 51
        for i = 1:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) =  min(min(byPixel((j-1)*60:(j*60-1), i)), 0);
        %    minVector(1, i) = max(0, byPixel((j-1)*6, i) - min(byPixel((j-1)*6:(j*6-1), i)));
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel((j-1)*6-1, i));
        %    demand(1, i) = minVector(1, i);
        %end
    else
        for i = 0:5
            byPixel((j-1)*6 + i, :) = byPixel((j-1)*6 + i, :) + byPixel((j-1)*6 + i-1, :);
            maxUnserved = min(maxUnserved, min(byPixel((j-1)*6 + i, :)));
        end
        %for i = 1:scale
        %    minVector(1, i) =  min(min(byPixel((j-1)*60:(j*60-1), i)), 0);
        %    minVector(1, i) = max(0, byPixel((j-1)*6, i) - min(byPixel((j-1)*6:(j*6-1), i)));
        %    minVector(1, i) = abs(minVector(1,i));
        %    supply(1, i) = max(0, byPixel((j-1)*6-1, i));
        %    demand(1, i) = minVector(1, i);
        %end
    end
    
    %beq = transpose(supply - demand);
    beq = transpose(byPixel(j*6 - 1, :));
    
    if min(beq) < 0
        [sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(number,1));
        if j == 1
            repositionedMiles(240, 1) = fval;
        else
            repositionedMiles(j-1, 1) = fval;
        end
        finalsol = zeros(scale, scale);
        for i = 1:length(combinedP.XPixel)
            for k = 1:length(combinedP.YPixel)
                finalsol(i, k) = sol(scale*(i-1) + k);
            end
        end
        for i = 1:scale
            newtaxis = sum(transpose(finalsol(:, i)));
            leavingtaxis = sum(finalsol(i, :));
            if j == 1
                byPixel(1440, i) = byPixel(1440, i) + newtaxis - leavingtaxis;
                byPixel(1:5, i) = byPixel(1:5, i) + newtaxis - leavingtaxis;
            elseif j == 51
                byPixel((j-1)*6 + 1:j*6-1, i) = byPixel((j-1)*6 + 1:j*6-1, i) + newtaxis - leavingtaxis;
            else
                byPixel((j-1)*6:j*6-1, i) = byPixel((j-1)*6:j*6-1, i) + newtaxis - leavingtaxis;
            end
        end
    else
        if j == 1
            repositionedMiles(240, 1) = 0;
        else
            repositionedMiles(j-1, 1) = 0;
        end
    end
    if j == 1
        repositionedTaxis(240, 1) = -sum(beq(beq < 0));
    else
         repositionedTaxis(j-1, 1) = -sum(beq(beq < 0));
    end
end 
%% end of day repositioning
beq = transpose(byPixel(299, :) - byPixel(300, :));
for k = 1:scale
    demands(k, 1) = min(beq(k,1), 0); 
end 
beq = transpose(byPixel(299, :)) + demands; 
[sol, fval] = intlinprog(cost, emptyTrip, -Aeq, beq, [], [], zeros(number,1));
repositionedTaxis(50, 1) = abs(sum(demands)); % changed from 5 to 50
repositionedMiles(50, 1) = fval;  % changed from 5 to 50
%% 
disp('Max Unserved');
maxUnserved
%%
results = table(repositionedMiles, repositionedTaxis);
writetable(results, 'Reposition10xHourHarris_v7.csv');
%csvwrite('LAPixelHour.csv', byPixel); 