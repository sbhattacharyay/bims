function plotAUC(preds_mat, out_filename)
    %% add helper functions to path
    addpath(genpath('functions'))
    %% get classes
    classes = who(matfile(preds_mat));
    %% load mat file
    clin_only_predictions = load(preds_mat, classes{1}).(classes{1});
    combined_predictions = load(preds_mat, classes{2}).(classes{2});
    mf_only_predictions = load(preds_mat, classes{3}).(classes{3});
    %% store names of model classifiers
    mf_classifiers = fieldnames(mf_only_predictions{1});
    mf_classifiers = mf_classifiers(2:end);

    cm_classifiers = fieldnames(combined_predictions{1});
    cm_classifiers = cm_classifiers(2:end);

    cl_classifiers = fieldnames(clin_only_predictions{1});
    cl_classifiers = cl_classifiers(2:end);
    
    %% build subplots
    aucfig = figure('units','normalized','outerposition',[0 0 1 1]);
    for i=1:length(mf_classifiers)
        [X,Y,T,AUC] = perfcurve(cellfun(@(x) horzcat(x.ground_truth-1),combined_predictions,'UniformOutput',false),...
                        cellfun(@(x) horzcat(x.(cm_classifiers{i})),combined_predictions,'UniformOutput',false),...
                        1,'XCrit','fpr','YCrit','tpr'); 
        [X1,Y1,T1,AUC1] = perfcurve(cellfun(@(x) horzcat(x.ground_truth-1),mf_only_predictions,'UniformOutput',false),...
                                cellfun(@(x) horzcat(x.(mf_classifiers{i})),mf_only_predictions,'UniformOutput',false),...
                                1,'XCrit','fpr','YCrit','tpr');                                         

        [X2,Y2,T2,AUC2] = perfcurve(cellfun(@(x) horzcat(x.ground_truth-1),clin_only_predictions,'UniformOutput',false),...
                                cellfun(@(x) horzcat(x.(cl_classifiers{i})),clin_only_predictions,'UniformOutput',false),...
                                1,'XCrit','fpr','YCrit','tpr');    

        legend_description = {sprintf('Combined\nAUC = %0.2f\n(%0.2f-%0.2f)',AUC(1),AUC(2),AUC(3));...
               sprintf('Motion Feature-only\nAUC = %0.2f\n(%0.2f-%0.2f)',AUC1(1),AUC1(2),AUC1(3));...
               sprintf('Clinical-only\nAUC = %0.2f\n(%0.2f-%0.2f)',AUC2(1),AUC2(2),AUC2(3))};
        subplot(2,4,i)
        plot(X(:,1),Y(:,1),'Color','#0072BD','LineWidth',3)
        hold on
        plot(X1(:,1),Y1(:,1),'Color','#A2142F','LineWidth',3)
        plot(X2(:,1),Y2(:,1),'Color','#000000','LineWidth',3)
        xlim([0 1])
        ylim([0 1])
        xticks(0:0.2:1)
        yticks(0:0.2:1)
        axis square
        title(upper(cl_classifiers{i}))
        ylabel('True positive rate')
        xlabel('False positive rate')
        set(gca,'FontSize',10)
        legend(legend_description, 'Location','southeast','Box','off')
    end
    %% save plot
    saveas(aucfig,[generateRootDir('AUC'),filesep,out_filename],'png');
end


% importing data from R to MATLAB:
% >>library('rmatio')
% >>write.mat(list, filename = 'preds_list.mat', compression = TRUE, version = c("MAT5"))
% clinical only character to factor conversion issue fix:
% >>list[[2]][[1]]$ground_truth <- as.factor(c(as.character(list[[2]][[1]]$ground_truth))) 
              %1:5                                                    %1:5