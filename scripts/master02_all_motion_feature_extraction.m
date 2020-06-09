%% Master Script 2: Complete Motion Feature Extraction
% Decoding Quantitative Motor Features for Classification and Prediction
% in Severe Acquired Brain Injury
%
% Shubhayu Bhattacharyay
% Department of Biomedical Engineering
% Department of Applied Mathematics and Statistics
% Whiting School of Engineering, Johns Hopkins University
% email address: shubhayu@jhu.edu
%% ------------- BEGIN CODE --------------
%Set Directory and Procure File Names
tic
addpath('functions/')

patientData = readtable('../clinical_data/SB_patient_table.xlsx',...
    'TreatAsEmpty',{'.','NA'});
patientData = sortrows(patientData,'AccelPatientNo_');

try
    cd('~/data/accel_sensor_data')
    marcc = true;
catch
    cd('../accel_sensor_data')
    marcc = false;
end

d = dir('data*');

studyPatients = cellfun(@(x) (string(x(5:6))),{d.name}');
studyDirs = {d.name}';

toc
%% Arrange data by time and cut out extraneous times
%WARNING: Elapsed Time: ~111.286133 seconds.
%WARNING: Elapsed Time: ~1104.244113 seconds for mega streams.

for patIdx = 1:length(studyDirs)
    tic
    
    if marcc == true
        folder_of_interest = ['~/data/accel_sensor_data/' studyDirs{patIdx}];
        disp(['Patient No. ' folder_of_interest(30:31) ' initiated.']);
        curr_AccelPatientNo = str2double(folder_of_interest(30:31));
    else
        folder_of_interest = ['../accel_sensor_data/',studyDirs{patIdx}];
        disp(['Patient No. ' folder_of_interest(26:27) ' initiated.']);
        curr_AccelPatientNo = str2double(folder_of_interest(26:27));
    end
    
    table_row_idx = find(patientData.AccelPatientNo_ == ... 
        curr_AccelPatientNo);

    try
        load(folder_of_interest)
    catch
        cd(folder_of_interest)
        load('C1.mat')
        load('C2.mat')
        load('C3.mat')
        load('C4.mat')
        load('C5.mat')
        load('C6.mat')
        load('C7.mat')
        data = [C1;C2;C3;C4;C5;C6;C7]';
    end
    toc
    %%
    tic
    %Filter Data (bworth 4-th order)
    fc = 0.2;
    fs = 10;
    [b,a] = butter(4,fc/(fs/2),'high');
    data_copy = cell(size(data));
    
    for i = 1:length(data(1,:))
        start_date = patientData.AccelRecordingStartDate(table_row_idx);
        % Date correction for Patient 21, Left Elbow Sensor (#3)
        if patIdx == 20 && i == 3
            start_date = start_date+1;
        end
        curr = data(:,i);
        x = filter(b,a,curr{5});
        y = filter(b,a,curr{6});
        z = filter(b,a,curr{7});
        time = string(curr{12});
        time_cut = extractBefore(time,13);
        dt_info = strcat(string(start_date),{' '},time_cut);
        time_dn = datenum(dt_info,'dd-mmm-yyyy HH:MM:SS:FFF');
        time_diff = (diff(time_dn));
        [max_diffs,date_change_Idx] = findpeaks(-time_diff,'MinPeakHeight',.1,'MinPeakDistance',10);
        time_dn_fixed = time_dn;
        if length(max_diffs) >= 1
            date_change_Idx = date_change_Idx+1;
            disp(['Additional ' num2str(length(date_change_Idx)) ' Day(s) Detected for Current Sensor ' num2str(i)])
            for j = 1:length(date_change_Idx)
                time_dn_fixed(date_change_Idx(j):end) = time_dn_fixed(date_change_Idx(j):end)+1;
            end
        end
        data_copy{5,i} = x;
        data_copy{6,i} = y;
        data_copy{7,i} = z;
        data_copy{12,i}= time_dn_fixed;
    end
    
    %Delete Extraneous Rows
    data_copy(1:4,:) = [];
    data_copy(4:7,:) = [];
    
    toc
    %% Feature Extraction
    %Warning! Run Time: >937.769720 seconds.
    tic
    
    SMA= {};
    freqPairs = {};
    medF = {};
    bandPower = {};
    freqEnt = {};
    wavelets = {};
    
    windowingStart = datenum(dateshift(datetime(min(cellfun(@(x) x(1), ...
        data_copy(4,:))),'ConvertFrom', 'datenum'),'start','minute',....
        5));
    windowingEnd = datenum(dateshift(datetime(max(cellfun(@(x) x(end),...
        data_copy(4,:))),'ConvertFrom', 'datenum'),'start','minute',....
        -5));
    windowSize = 5; %in seconds
    window = windowSize/86400;
    
    timeSplit = windowingStart:window:windowingEnd;
    
    binCount = length(timeSplit)-1;
    binIdx = 1:binCount;
    
    for j = 1:length(data_copy)

        split_Data = cell(binCount,4);
        
        x_stream = data_copy{1,j};
        y_stream = data_copy{2,j};
        z_stream = data_copy{3,j};
        t_stream = data_copy{4,j};
        
        [NCounts, ~, indices] = histcounts(t_stream,timeSplit);
        totalIdx = indices';
        
        nonMP = NCounts>40;        
        availBins = find(nonMP);
        
        split_Data(nonMP,1) = arrayfun(@(curr_bin) x_stream(totalIdx==curr_bin),availBins,'UniformOutput', false);
        split_Data(nonMP,2) = arrayfun(@(curr_bin) y_stream(totalIdx==curr_bin),availBins,'UniformOutput', false);
        split_Data(nonMP,3) = arrayfun(@(curr_bin) z_stream(totalIdx==curr_bin),availBins,'UniformOutput', false);
        split_Data(nonMP,4) = arrayfun(@(curr_bin) t_stream(totalIdx==curr_bin),availBins,'UniformOutput', false);
        lens = cellfun(@(x) length(x),split_Data(:,1));
        times = datestr(timeSplit(2:end)');
                
        X = split_Data(:,1);
        Y = split_Data(:,2);
        Z = split_Data(:,3);
        T = split_Data(:,4);
        
        maskx = binIdx(cellfun(@(x) ~isempty(x), X));
        masky = binIdx(cellfun(@(y) ~isempty(y), Y));
        maskz = binIdx(cellfun(@(z) ~isempty(z), Z));
        maskt = binIdx(cellfun(@(t) ~isempty(t), T));
        
        superMask = intersect(maskx,masky);
        superMask = intersect(superMask,maskz);
        superMask = intersect(superMask,maskt);
        
        %SMA
        curr_sma = NaN(binCount,1);
        curr_sma(superMask) = ((window)^-1).*cellfun(@(x,y,z,t) trapz(t,abs(x)+abs(y)+abs(z)), ...
            X(superMask),Y(superMask),Z(superMask),T(superMask));
        SMA = [SMA {curr_sma;times;lens}];
        %Frequency component median pairs
        
        curr_Med = NaN(binCount,2);
        fc = 2.5;
        fs = 10;
        [b,a] = butter(4,fc/(fs/2),'high');
        [d,c] = butter(4,fc/(fs/2),'low');
        
        curr_Med(superMask,1) = cellfun(@(x,y,z,t) rssq([median(filter(d,c,x)),...
            median(filter(d,c,y)),median(filter(d,c,z))]),....
            X(superMask),Y(superMask),Z(superMask),T(superMask));
        
        curr_Med(superMask,2) = cellfun(@(x,y,z,t) rssq([median(filter(b,a,x)),...
            median(filter(b,a,y)),median(filter(b,a,z))]),....
            X(superMask),Y(superMask),Z(superMask),T(superMask));
        
        freqPairs = [freqPairs {curr_Med;times;lens}];
        
        %Median Freq
        curr_medFreq = NaN(binCount,1);
        curr_medFreq(superMask)=cellfun(@(x,y,z,t) rssq([medfreq(x),medfreq(y),medfreq(z)]), ...
            X(superMask),Y(superMask),Z(superMask),T(superMask));
        
        medF = [medF {curr_medFreq;times;lens}];
        
        %Band Power
        curr_bandPower = NaN(binCount,1);
        curr_bandPower(superMask)=cellfun(@(x,y,z,t) rssq([bandpower(x,fs,[0.3 3.5]), ...
            bandpower(y,fs,[0.3 3.5]),bandpower(z,fs,[0.3 3.5])]),....
            X(superMask),Y(superMask),Z(superMask),T(superMask));
        
        bandPower = [bandPower {curr_bandPower;times;lens}];
        
        %Frequency-Domain Entropy
        curr_freqEnt = NaN(binCount,1);
        curr_freqEnt(superMask)=cellfun(@(x,y,z) rssq([pentropy(x,fs,'Instantaneous',false),...
            pentropy(y,fs,'Instantaneous',false),pentropy(z,fs,'Instantaneous',false)]), ....
            X(superMask),Y(superMask),Z(superMask));
        
        freqEnt = [freqEnt {curr_freqEnt;times;lens}];
        %wavelets
        if marcc == true
            cd('~/data/accel_sensor_data')
        else
            cd('../accel_sensor_data')
        end
        
        curr_wvlt = NaN(binCount,1);
        curr_wvlt(superMask)=cellfun(@(x,y,z) get_wavelets(x,y,z), ...
            X(superMask),Y(superMask),Z(superMask));
        
        wavelets = [wavelets {curr_wvlt;times;lens}];
    end
    
    if marcc == true
        save(['~/data/all_motion_feature_data/band_power/band_power' folder_of_interest(30:31) '.mat'],'bandPower','-v7.3');
        save(['~/data/all_motion_feature_data/freq_entropy/freq_entropy' folder_of_interest(30:31) '.mat'],'freqEnt','-v7.3');
        save(['~/data/all_motion_feature_data/freq_pairs/freq_pairs' folder_of_interest(30:31) '.mat'],'freqPairs','-v7.3');
        save(['~/data/all_motion_feature_data/med_freq/med_freq' folder_of_interest(30:31) '.mat'],'medF','-v7.3');
        save(['~/data/all_motion_feature_data/sma/sma' folder_of_interest(30:31) '.mat'],'SMA','-v7.3');
        save(['~/data/all_motion_feature_data/wavelets/wavelets' folder_of_interest(30:31) '.mat'],'wavelets','-v7.3');
        disp(['Patient No. ' folder_of_interest(30:31) ' completed.']);
    else
        save(['../all_motion_feature_data/band_power/band_power' folder_of_interest(26:27) '.mat'],'bandPower','-v7.3');
        save(['../all_motion_feature_data/freq_entropy/freq_entropy' folder_of_interest(26:27) '.mat'],'freqEnt','-v7.3');
        save(['../all_motion_feature_data/freq_pairs/freq_pairs' folder_of_interest(26:27) '.mat'],'freqPairs','-v7.3');
        save(['../all_motion_feature_data/med_freq/med_freq' folder_of_interest(26:27) '.mat'],'medF','-v7.3');
        save(['../all_motion_feature_data/sma/sma' folder_of_interest(26:27) '.mat'],'SMA','-v7.3');
        save(['../all_motion_feature_data/wavelets/wavelets' folder_of_interest(26:27) '.mat'],'wavelets','-v7.3');
        disp(['Patient No. ' folder_of_interest(26:27) ' completed.']);
    end
    toc
end

license('inuse')