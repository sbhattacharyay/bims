%% Master Script 4: Collect Motion Features
% Decoding Quantitative Motor Features for Classification and Prediction
% in Severe Acquired Brain Injury
%
% Shubhayu Bhattacharyay, Matthew Wang
% Department of Biomedical Engineering
% Department of Applied Mathematics and Statistics
% Whiting School of Engineering, Johns Hopkins University
% email address: shubhayu@jhu.edu
%% ------------- BEGIN CODE --------------
% Feature collection and organization script

cd ../tod_motion_feature_data/

sensors = cell(7,6);
directory = dir;
feature_count = 0;
feature_names = [];

for i = 1:length(directory)
    if (directory(i).isdir==1 && directory(i).name ~= "."&& directory(i).name ~= "..")
        feature_count = feature_count+1;
        feature_names = [feature_names string(directory(i).name)];
        folder = [pwd filesep directory(i).name];
        temp_dir = dir(folder);
        for j = 3:length(temp_dir)
            temp_data=struct2cell(load([folder filesep temp_dir(j).name]));
            temp_data=temp_data{1};
            for k = 1:7
                sensors{k,feature_count} = [sensors{k,feature_count}; temp_data{1,k}'];
            end
        end
    else
        continue
    end
end

% Organizing the frequency pairs dataset

%At this point the frequency pairs are all combined in the same (nx2)x12959
%matrix. However, we would like to split up the high and low frequency
%matrices. Thus, the odd rows will be partitioned to one matrix while the
%even rows to another:

[n,~] = size(sensors{1,3});

freqPair1 = cellfun(@(x) x(1:2:(n-1),:),sensors(:,3),'UniformOutput',false);
freqPair2 = cellfun(@(x) x(2:2:n,:),sensors(:,3),'UniformOutput',false);

sensors(:,5:7)=sensors(:,4:6);
sensors(:,3)=freqPair1;
sensors(:,4)=freqPair2;

feature_names = [feature_names(1:2),strcat(feature_names(3),"1"),...
    strcat(feature_names(3),"2"),feature_names(4:6)];

%%  Saving the data
save('complete_sensor_data.mat','sensors','feature_names');

%%
cd ../tfr_motion_feature_data/

sensors = cell(7,6);
directory = dir;
feature_count = 0;
feature_names = [];

for i = 1:length(directory)
    if (directory(i).isdir==1 && directory(i).name ~= "."&& directory(i).name ~= "..")
        feature_count = feature_count+1;
        feature_names = [feature_names string(directory(i).name)];
        folder = [pwd filesep directory(i).name];
        temp_dir = dir(folder);
        for j = 3:length(temp_dir)
            temp_data=struct2cell(load([folder filesep temp_dir(j).name]));
            temp_data=temp_data{1};
            for k = 1:7
                sensors{k,feature_count} = [sensors{k,feature_count}; temp_data{1,k}'];
            end
        end
    else
        continue
    end
end

% Organizing the frequency pairs dataset

%At this point the frequency pairs are all combined in the same (nx2)x12959
%matrix. However, we would like to split up the high and low frequency
%matrices. Thus, the odd rows will be partitioned to one matrix while the
%even rows to another:

[n,~] = size(sensors{1,3});

freqPair1 = cellfun(@(x) x(1:2:(n-1),:),sensors(:,3),'UniformOutput',false);
freqPair2 = cellfun(@(x) x(2:2:n,:),sensors(:,3),'UniformOutput',false);

sensors(:,5:7)=sensors(:,4:6);
sensors(:,3)=freqPair1;
sensors(:,4)=freqPair2;

feature_names = [feature_names(1:2),strcat(feature_names(3),"1"),strcat(feature_names(3),"2"),feature_names(4:6)];

%%  Saving the data
save('complete_sensor_data.mat','sensors','feature_names');

cd ../scripts/

license('inuse')