% Post-processing script for the EST Simulink model.
% This script is invoked after the Simulink model is finished running (stopFcn callback function).

close all;
figure;

% Helper function to extract .Data if timeseries, otherwise return input

% Extract all relevant signals safely
PSupplyData = getData(PSupply);
PDemandData = getData(PDemand);
EStorageData = getData(EStorage);
DData = getData(D);
PSellData = getData(PSell);
PBuyData = getData(PBuy);
PfromSupplyTransportData = getData(PfromSupplyTransport);
PtoDemandTransportData = getData(PtoDemandTransport);
PtoInjectionData = getData(PtoInjection);
PfromExtractionData = getData(PfromExtraction);
DStorageData = getData(DStorage);
h_outData = getData(h_energy);


%% Supply and demand
subplot(3,2,1);
plot(tout/unit("day"), PSupplyData/unit("kW"));
hold on;
plot(tout/unit("day"), PDemandData/unit("kW"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [kW]');
legend("Supply","Demand");

%% Stored energy
subplot(3,2,2);
plot(tout/unit("day"), EStorageData/unit("J"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Storage');
xlabel('Time [day]');
ylabel('Energy [J]');

%% Energy losses
subplot(3,2,3);
plot(tout/unit("day"), DData/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Losses');
xlabel('Time [day]');
ylabel('Dissipation rate [W]');

%% Load balancing
subplot(3,2,4);
plot(tout/unit("day"), PSellData/unit("W"));
hold on;
plot(tout/unit("day"), PBuyData/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load balancing');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Sell","Buy");

%% Tank water height
subplot(3,2,[5 6]);
if exist('h_outData', 'var') && all(isfinite(h_outData)) && any(h_outData < 0)
    plot(tout/unit("day"), h_outData, 'b');
    xlim([0 tout(end)/unit("day")]);
    grid on;
    title('Water Height in Tanks');
    xlabel('Time [day]');
    ylabel('Height [m]');
else
    warning("Tank water height (h_out) is missing or invalid. Skipping plot.");
end

%% Pie charts
% integrate the power signals in time
EfromSupplyTransport = trapz(tout, PfromSupplyTransportData);
EtoDemandTransport   = trapz(tout, PtoDemandTransportData);
ESell                = trapz(tout, PSellData);
EBuy                 = trapz(tout, PBuyData);
EtoInjection         = trapz(tout, PtoInjectionData);
EfromExtraction      = trapz(tout, PfromExtractionData);
EStorageDissipation  = trapz(tout, DStorageData);
EDirect              = EfromSupplyTransport - ESell - EtoInjection;
ESurplus             = EtoInjection - EfromExtraction - EStorageDissipation;

% Protect against NaNs, Infs, or divide-by-zero
figure;
tiles = tiledlayout(1,2);

leftData = [EDirect, EtoInjection, ESell];
rightData = [EDirect, EfromExtraction, EBuy];

if all(isfinite(leftData)) && sum(leftData) > 0
    ax = nexttile;
    pie(ax, leftData/sum(leftData));
    lgd = legend({"Direct to demand", "To storage", "Sold"});
    lgd.Layout.Tile = "south";
    title(sprintf("Received energy %3.2e [J]", EfromSupplyTransport/unit('J')));
else
    warning("Invalid data in received energy pie chart — skipping.");
end

if all(isfinite(rightData)) && sum(rightData) > 0
    ax = nexttile;
    pie(ax, rightData/sum(rightData));
    lgd = legend({"Direct from supply", "From storage", "Bought"});
    lgd.Layout.Tile = "south";
    title(sprintf("Delivered energy %3.2e [J]", EtoDemandTransport/unit('J')));
else
    warning("Invalid data in delivered energy pie chart — skipping.");
end

%% Helper function
function out = getData(x)
    if isstruct(x) && isfield(x, 'Data')
        out = x.Data;
    elseif isa(x, 'timeseries')
        out = x.Data;
    else
        out = x;
    end
end

