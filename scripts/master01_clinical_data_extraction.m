%% Master Script 1: Clinical Data Extraction
% Decoding Quantitative Motor Features for Classification and Prediction
% in Severe Acquired Brain Injury
%
% Shubhayu Bhattacharyay
% Department of Biomedical Engineering
% Department of Applied Mathematics and Statistics
% Whiting School of Engineering, Johns Hopkins University
% email address: shubhayu@jhu.edu
%% ------------- BEGIN CODE --------------
% Load data from most recent patient clinical data spreadsheet
addpath('functions/')

patientData = readtable('../clinical_data/Final_BIMS.xlsx','TreatAsEmpty',{'.','NA'});
clinicalVariableList = readtable('../clinical_data/clinicalVariableList.csv');

% Assign variable names to patient datasheet
patientData.Properties.VariableNames([1:3,7,13:18,24:25,27:30,32,41:42, ...
    50:51,60,69,71,73,83,85])={'pNum','gender','age','los','stroke', ....
    'ich','sah','bt','sdh','tbi','hlm_en','hlm_dis','ampac_en_r', .....
    'ampac_en_t','ampac_dis_r','ampac_dis_t','apache','gcs_m_en', ......
    'gcs_en','gcs_m_dis','gcs_dis','jfk_en','jfk_dis','gose', .......
    'death','gose_12mo','outcome_12mo'};

% Remove extraneous cells in spreadsheet
excluded = isnan(patientData.pNum) | isnan(patientData.gose) | ...
    patientData.pNum==1;
patientData(excluded,:) = [];
patientData(:,all(ismissing(patientData)))=[];
% Indices of patients to use in study. To see exclusion criteria, please
% refer to Materials and Methods section
studyPatients = [2,3,4,5,6,7,8,9,10,11,12,13,14,15, ...
    16,17,18,19,20,21,22,23,24,26,27,28,29,30,31,32,33, ....
    34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50, .....
    51,52,53,54,55,58,59,60,61,62,63,64,66,67];
PY_pNum = [2,3,4,5,6,7,8,9,10,11,12,13, ...
    14,15,16,17,18,19,20,21,22,23,24,26,27,28,29,30, ....
    31,32,33,34,35,36,37,38,39,40,41,42,43,49,51,46, .....
    47,48,50,52,53,54,55,56,57,59,60,61,62,63,64,65, ......
    67,68]';
patientData=addvars(patientData,PY_pNum,'Before','pNum');
favorable=patientData.gose>=4;
favorable_12mo=NaN(length(studyPatients),1);
favorable_12mo(patientData.gose_12mo>=4)=1;
favorable_12mo(patientData.gose_12mo<4)=0;
death_12mo=NaN(length(studyPatients),1);
death_12mo(patientData.outcome_12mo==1)=1;
death_12mo(patientData.outcome_12mo==0)=0;

patientData=addvars(patientData,favorable);
patientData=addvars(patientData,favorable_12mo);
patientData=addvars(patientData,death_12mo);

patientData.Properties.VariableNames=clinicalVariableList.variable;
writetable(patientData,'../clinical_data/patient_clinical_data.csv');
%% Extract Outcome Information from Patient Dataset

fav_threshold = 4; % GOSE >= fav_threshold is favorable

% Extract outcome scores (GOSE) at discharge
gose_scores = patientData.gose;
gose_scores(3) = '3'; % Fix single ambiguous GOSE score in dataset
gose_scores = (gose_scores);

% Extract outcome scores (GOSE) at 12 months (for patients for which data
% is available).
yr_outcome_code = (patientData.outcome_12mo);
yr_outcome_code = yr_outcome_code;

gose_12months = patientData.gose_12mo;
gose_12months = gose_12months;

noYearOutcomeAvailable = isnan(gose_12months);

% Define functional outcomes (favorable outcomes as GOSE >= 4)
dc_outcomes = double(gose_scores>= fav_threshold); %discharge functional outcomes (F vs. UF)
yr_outcomes = double(gose_12months>= fav_threshold);
yr_outcomes(noYearOutcomeAvailable) = NaN;

% Mortality outcomes at discharge and 1 year
dc_death = (patientData.death);
yr_death = double(gose_12months==1);
yr_death(noYearOutcomeAvailable) = NaN;

%% Clinical Data Preprocessing and Imputation

% Apply LLF-optimized box-cox transform to quantitative clinical variables
% and normalize dataset to enable hypothesis testing:

% Age:
[age,lam_age]=boxcox((patientData.age));
[age,mu_age,sig_age]=zscore(age);

% GCS at enrollment:
[gcs_scores_en,lam_gcs_en]=boxcox((patientData.gcs_en));
[gcs_scores_en,mu_gcs_en,sig_gcs_en]=zscore(gcs_scores_en);

% APACHE at enrollment:
[apache_scores,lam_apache]=boxcox((patientData.apache));
[apache_scores,mu_apache,sig_apache]=zscore(apache_scores);

% GCS at discharge:
[gcs_scores_dis,lam_gcs_dis]=boxcox((patientData.gcs_dis));
[gcs_scores_dis,mu_gcs_dis,sig_gcs_dis]=zscore(gcs_scores_dis);

% Gender (Males are 1, Females are -1):
females = categorical(patientData.gender)~= 'M';
gender = (-1).^females;

% Diagnosis codes
stroke = -((-1).^(patientData.stroke));
ich = -((-1).^(patientData.ich));
sah = -((-1).^(patientData.sah));
bt = -((-1).^(patientData.bt));
sdh = -((-1).^(patientData.sdh));
tbi = -((-1).^(patientData.tbi));

% Impute missing clinical variables with Weighted k-NN (code below)
dataset = [age gender stroke ich sah bt sdh tbi apache_scores ...
    gcs_scores_en gcs_scores_dis];
imputedPatientDataset = [patientData.PY_pNum,patientData.pNum,...
    wKNN_impute(dataset)];

% % AMPAC at enrollment:
% [ampac_en_r,lam_ampac]=boxcox(cell2mat(patientData.ampac_en_r));
% [ampac_en_r,mu_ampac,sig_ampac]=zscore(ampac_en_r);
%
% % HLM at enrollment:
% [hlm_en,lam_hlm_en]=boxcox(patientData.hlm_en);
% [hlm_en,mu_hlm_en,sig_hlm_en]=zscore(hlm_en);
%
% % JFK at enrollment:
% [jfk_en,lam_jfk_en]=boxcox(patientData.jfk_en);
% [jfk_en,mu_jfk_en,sig_jfk_en]=zscore(jfk_en);

%% Prepare predictor matrices:

% Penultimate column is death and final column is GOSE
dc_dataset = [imputedPatientDataset(:,1:(end-1)) dc_death dc_outcomes];

% Remove patients who lack 1 year outcomes to form 1-year outcomes dataset
yr_dataset = [imputedPatientDataset(~noYearOutcomeAvailable,:) ...
    yr_death(~noYearOutcomeAvailable) ....
    yr_outcomes(~noYearOutcomeAvailable)];

all_patient_dataset = [imputedPatientDataset,dc_death,dc_outcomes,yr_death, ...
    yr_outcomes];

dc_dataset_labels=["PY_pNum","pNum","Age","Sex","CVA","ICH","SAH","BT",...
    "SDH","TBI","APACHE","GCS_{en}","Death","GOSE"];
yr_dataset_labels=["PY_pNum","pNum","Age","Sex","CVA","ICH","SAH","BT",...
    "SDH","TBI","APACHE","GCS_{en}","GCS_{dis}","Death","GOSE"];

patient_table_labels=["PY_pNum","pNum","Age","Sex","CVA","ICH","SAH",...
    "BT","SDH","TBI","APACHE","GCS_en","GCS_dis","Death","GOSE",....
    "Death_1yr","GOSE_1yr"];

tf_patient_covariates=array2table(all_patient_dataset,'VariableNames', ...
    patient_table_labels);

boxcox_lambdas = [lam_age,lam_apache,lam_gcs_en,lam_gcs_dis];
zscore_mus = [mu_age,mu_apache,mu_gcs_en,mu_gcs_dis];
zscore_sigs = [sig_age,sig_apache,sig_gcs_en,sig_gcs_dis];

clearvars -except dc_dataset yr_dataset dc_dataset_labels ...
    yr_dataset_labels boxcox_lambdas zscore_mus zscore_sigs ....
    imputedPatientDataset studyPatients tf_patient_covariates

save('../clinical_data/clinical_extraction_output.mat')

%% Visualize distribution of transformed (Box-Cox) clinical variables
figure
for i =1:5
    subplot(2,3,i);
    histogram(imputedPatientDataset(:,i),30);
    title(yr_dataset_labels(i));
end

%% Visualize outcome distributions
figure
subplot(2,2,1);
pie(categorical(dc_dataset(:,(end-1))))
title('Died during hospital stay')

subplot(2,2,2);
pie(categorical(dc_dataset(:,(end))))
title('GOSE >= 4 at discharge')

subplot(2,2,3);
pie(categorical(yr_dataset(:,(end-1))))
title('Died within 1 year of discharge')

subplot(2,2,4);
pie(categorical(yr_dataset(:,(end))))
title('GOSE >= 4 within 1 year of discharge')

license('inuse')
%------------- END OF CODE --------------
