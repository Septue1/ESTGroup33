% Post-processing script for the EST Simulink model.
% This script is invoked after the Simulink model is finished running (stopFcn callback function).

close all;

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


%% Supply and Demand
idx_filtered = find(mod(tout, 86400) == 0);  % find index for the first second in a week
time_weeks = tout(idx_filtered) / unit("week");
samples_per_week = 86400 / mean(diff(tout)); 
n_weeks = floor(length(tout) / samples_per_week);

weekly_sums_supply = [PSupplyData(1); zeros(n_weeks, 1)];
for i = 1:n_weeks
    idx_start = round((i - 1) * samples_per_week) + 1;
    idx_end = round(i * samples_per_week);
    weekly_sums_supply(i) = sum(PSupplyData(idx_start:idx_end));
end
weekly_sums_demand = [PDemandData(1); zeros(n_weeks, 1)];
for i = 1:n_weeks
    idx_start = round((i - 1) * samples_per_week) + 1;
    idx_end = round(i * samples_per_week);
    weekly_sums_demand(i) = sum(PDemandData(idx_start:idx_end));
end
fig = figure;
plot(time_weeks, weekly_sums_supply/unit("W"));
hold on;
plot(time_weeks, weekly_sums_demand/unit("W"));
xlim([0 time_weeks(end)]);
grid on;
title('Supply and Demand ');
xlabel('Time [week]');
ylabel('Power [W]');
legend("Supply","Demand");
set(gcf, 'Position', [100, 100, 1000, 400]);
saveas(fig, 'fig_supply_demand.png');

%% Stored Energy
fig = figure;
plot(time_weeks, EStorageData(idx_filtered)/unit("J"));
xlim([0 tout(end)/unit("week")]);
grid on;
title('Stored Energy');
xlabel('Time [week]');
ylabel('Energy [J]');
set(gcf, 'Position', [100, 100, 1000, 400]);
saveas(fig, 'fig_stored_energy.png');

%% Energy Losses
weekly_sums_loss = [DData(1); zeros(n_weeks, 1)];
for i = 1:n_weeks
    idx_start = round((i - 1) * samples_per_week) + 1;
    idx_end = round(i * samples_per_week);
    weekly_sums_loss(i) = sum(DData(idx_start:idx_end));
end
fig = figure;
plot(time_weeks, weekly_sums_loss/unit("W"));   
xlim([0 tout(end)/unit("week")]);
grid on;
title('Energy Losses');
xlabel('Time [week]');
ylabel('Dissipation Rate [W]');
set(gcf, 'Position', [100, 100, 1000, 400]);
saveas(fig, 'fig_energy_losses.png');

%% Load Balancing
weekly_sums_sell = [PSellData(1); zeros(n_weeks, 1)];
for i = 1:n_weeks
    idx_start = round((i - 1) * samples_per_week) + 1;
    idx_end = round(i * samples_per_week);
    weekly_sums_sell(i) = sum(PSellData(idx_start:idx_end));
end
weekly_sums_buy = [PBuyData(1); zeros(n_weeks, 1)];
for i = 1:n_weeks
    idx_start = round((i - 1) * samples_per_week) + 1;
    idx_end = round(i * samples_per_week);
    weekly_sums_buy(i) = sum(PBuyData(idx_start:idx_end));
end
fig = figure;
plot(time_weeks, weekly_sums_sell/unit("W"));
hold on;
plot(time_weeks, weekly_sums_buy/unit("W"));
xlim([0 tout(end)/unit("week")]);
grid on;
title('Load Balancing');
xlabel('Time [week]');
ylabel('Power [W]');
legend("Sell","Buy");
set(gcf, 'Position', [100, 100, 1000, 400]);
saveas(fig, 'fig_load_balancing.png');

%% Tank Water Height
if exist('h_outData', 'var') && all(isfinite(h_outData)) && any(h_outData >= 0)
    fig = figure;
    plot(time_weeks, h_outData(idx_filtered), 'b');
    xlim([0 tout(end)/unit("week")]);
    grid on;
    title('Water Height in Tanks');
    xlabel('Time [week]');
    ylabel('Height [m]');
    set(gca, 'YDir', 'reverse')
    set(gcf, 'Position', [100, 100, 1000, 400]);
    saveas(fig, 'fig_water_height.png');
else
    warning("Tank water height (h_out) is missing or invalid. Skipping plot.");
end

%% Pie Charts
EfromSupplyTransport = trapz(tout, PfromSupplyTransportData);
EtoDemandTransport   = trapz(tout, PtoDemandTransportData);
ESell                = trapz(tout, PSellData);
EBuy                 = trapz(tout, PBuyData);
EtoInjection         = trapz(tout, PtoInjectionData);
EfromExtraction      = trapz(tout, PfromExtractionData);
EStorageDissipation  = trapz(tout, DStorageData);
EDirect              = EfromSupplyTransport - ESell - EtoInjection;

leftData = [EDirect, EtoInjection, ESell];
rightData = [EDirect, EfromExtraction, EBuy];

if all(isfinite(leftData)) && sum(leftData) > 0
    fig = figure;
    pie(leftData/sum(leftData));
    legend({"Direct to demand", "To storage", "Sold"}, 'Location', 'southoutside');
    title(sprintf("Received energy: %3.2e [J]", EfromSupplyTransport/unit('J')));
    saveas(fig, 'fig_received_energy_pie.png');
else
    warning("Invalid data in received energy pie chart — skipping.");
end

if all(isfinite(rightData)) && sum(rightData) > 0
    fig = figure;
    pie(rightData/sum(rightData));
    legend({"Direct from supply", "From storage", "Bought"}, 'Location', 'southoutside');
    title(sprintf("Delivered energy: %3.2e [J]", EtoDemandTransport/unit('J')));
    saveas(fig, 'fig_delivered_energy_pie.png');
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