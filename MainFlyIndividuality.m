%% MainFlyIndividuality.m
%
% Reproduces the main figures from:
%   "Life Events Reshape Individuality in Flies Without Losing Consistency"
%   Forkosh et al., PLOS Biology, 2026
%
% USAGE:
%   Set opt.want2save = true to export figures to Figs/<experiment>/.
%   Set opt.computeAll = true to recompute the LDA projection (W) from
%   scratch; set false (default) to load the precomputed W from SupportFiles/.
%
% REQUIREMENTS:
%   MATLAB R2022b or later. See README.md for toolbox dependencies.
%
% DATA:
%   Download data files from https://doi.org/10.5281/zenodo.20339311
%   and place them in the Data/ folder.
%   Required: MainFemalesMales.mat, SocialContext.mat, Rejected30min.mat,
%             SocialDefeat.mat, Microbiome.mat

close all; clear; clc;

%% ── Parameters ──────────────────────────────────────────────────────────────
opt.datacol    = 6;      % first column index of behavioral scores in tables
opt.n_ids      = 4;      % number of identity dimensions to extract
opt.want2save  = false;  % set true to export figures as PDF/PNG/EPS/FIG
opt.wantStats  = true;   % overlay significance stars on violin plots
opt.norm       = false;  % z-score IDs before plotting (for display only)
opt.sameScale  = true;   % force same y-axis on all ID violin plots
opt.nSegs      = 2;      % number of temporal segments per recording
opt.computeAll = false;  % false = load precomputed W; true = recompute

mainDir = fileparts(mfilename('fullpath'));  % repo root (cross-platform)
addpath(genpath(mainDir));

%% ── Create output folders ────────────────────────────────────────────────────
experiments = {'MainFemalesMales','SocialContext','Rejected30min', ...
               'SocialDefeat','Microbiome'};
for k = 1:numel(experiments)
    d = fullfile(mainDir, 'Figs', experiments{k});
    if ~exist(d, 'dir'), mkdir(d); end
end

%% ── Behavior metadata ────────────────────────────────────────────────────────
meta = readtable(fullfile(mainDir, 'SupportFiles', 'allBehaviorsExplain.csv'));

%% ════════════════════════════════════════════════════════════════════════════
%%  SECTION 1 — Main experiment: Females & Males (grouped / isolated / mated)
%% ════════════════════════════════════════════════════════════════════════════
expName = 'MainFemalesMales';
opt.colors = dictionary( ...
    ["Grouped_females","Grouped_males","Isolated_females", ...
     "Isolated_males","Mated_females","Mated_males"], ...
    {[0.9922 0.7725 0.2980], [0.4627 0.7686 0.7059], ...
     [202 33 60]/255,        [0.5 0.12 0.5], ...
     [218 110 147]/255,      [0.1137 0.4118 0.6118]});

opt.colormap = cell2mat(opt.colors( ...
    ["Grouped_males","Isolated_males","Mated_males", ...
     "Grouped_females","Isolated_females","Mated_females"]));

% Load & preprocess
[fly, fullTable, conditionNames, W] = loadExperiment( ...
    expName, mainDir, meta, opt);

%% ── 1a. Compute individual identity (LDA) ───────────────────────────────────
data       = fullTable{:, opt.datacol:end};
[~, ~, flyidx] = unique([fullTable.fly, fullTable.movie_number], 'rows');

if opt.computeAll
    [W, ~] = DimReduction.LDA(data, flyidx, 8);
    % Sign conventions used in the paper
    W(:,1) = -W(:,1);  W(:,2) = -W(:,2);  W(:,4) = -W(:,4);
else
    tmp = load(fullfile(mainDir, 'SupportFiles', 'W.mat'));
    W   = tmp.W;
end

fly = projectOntoW(fly, fullTable, W, opt);

%% ── 1b. Fisher-Rao separability ─────────────────────────────────────────────
% Requires precomputed files: SupportFiles/fisher-rao-fly.mat,
%   fisher-rao-fly-random.mat, fisher-rao-mice.mat
fisherRaoFiles = fullfile(mainDir, 'SupportFiles', 'fisher-rao-fly.mat');
if exist(fisherRaoFiles, 'file')
    fr.fly    = load(fullfile(mainDir,'SupportFiles','fisher-rao-fly')).e;
    fr.random = load(fullfile(mainDir,'SupportFiles','fisher-rao-fly-random')).E;
    fr.mouse  = load(fullfile(mainDir,'SupportFiles','fisher-rao-mice')).e;

    tovec   = @(x) x(:);
    cmap_fr = [255,193,7; 34,139,34; 112,128,144] / 255;
    linebar = @(x,i) area( ...
        tovec([1:length(x); 2:length(x)+1]) - 0.5, ...
        tovec([tovec(x)'; tovec(x)']), ...
        'LineWidth',2,'FaceAlpha',.1, ...
        'EdgeColor',cmap_fr(i,:),'FaceColor',cmap_fr(i,:));

    figure('Name','Fisher-Rao separability');
    linebar(fr.fly, 1); hold on
    linebar(fr.mouse, 2)
    linebar(mean(fr.random), 3); hold off
    xlim([0.5, 8.5]);
    legend('Flies','Mice','Random'); legend boxoff
    xlabel('Number of components'); ylabel('Fisher-Rao separability');
    if opt.want2save, figtosave(expName, mainDir, 'Fisher-Rao'); end
end

%% ── 1c. Personality space — all condition-pair combinations ─────────────────
for id1 = 1:opt.n_ids
    for id2 = (id1+1):opt.n_ids
        figure
        plotIDs(fullTable, [id1,id2], 'W', fly.W, ...
            'colorBackgrounds', ones(1,3), 'colormap', opt.colormap);
        legend off
        if opt.want2save
            figtosave(expName, mainDir, sprintf('PersonalitySpace_ID%d_ID%d',id1,id2))
        end
    end
end

%% ── 1d. Baseline (grouped flies only) — all combinations ───────────────────
for id1 = 1:opt.n_ids
    for id2 = (id1+1):opt.n_ids
        figure; clf
        plotIDs(fullTable, [id1,id2], 'W', fly.W, ...
            'colorBackgrounds', ones(1,3), ...
            'conditions', {'Grouped_males','Grouped_females'}, ...
            'colormap', opt.colormap);
        legend off
        if opt.want2save
            figtosave(expName, mainDir, sprintf('BaseLine_ID%d_ID%d',id1,id2))
        end
    end
end

%% ── 1e. Density contour maps ────────────────────────────────────────────────
ids = [1, 2];  N = 500;  nlevels = 7;
xs  = [-.4 .4]; ys = [-.3 .3];

% All conditions together
figure('Name','Density map — all conditions')
conturMesh(fly, ids, N, nlevels, xs, ys, ...
    'conditionNames', conditionNames, 'colormap', opt.colormap)
Fig.Fix
if opt.want2save, figtosave(expName, mainDir, 'DensityMap_AllConditions'); end

% Males: grouped vs mated vs isolated
malePairs  = {{'Grouped_males','Mated_males'}, {'Grouped_males','Isolated_males'}};
femalePairs= {{'Grouped_females','Mated_females'},{'Grouped_females','Isolated_females'}};
maleColors = {opt.colormap([1,3],:); opt.colormap([1,2],:)};
femaleColors={opt.colormap([4,6],:); opt.colormap([4,5],:)};

for idss = {[1,2],[1,3],[2,3],[1,4],[2,4],[3,4]}
    currIds = idss{1};
    figure('Name', sprintf('Density map — ID%d vs ID%d', currIds(1), currIds(2)))
    for comp = 1:2
        subplot(2,2,comp)
        conturMesh(fly, currIds, N, nlevels, xs, ys, ...
            'conditionNames', malePairs{comp}, 'colormap', maleColors{comp})
        legend off
        set(gca,'XAxisLocation','origin','YAxisLocation','origin')
        Fig.Fix; hold off
        legend(strrep(malePairs{comp},'_',' '),'Location','bestoutside')
        xlabel(sprintf('ID%d',currIds(1))); ylabel(sprintf('ID%d',currIds(2)))

        subplot(2,2,comp+2)
        conturMesh(fly, currIds, N, nlevels, xs, ys, ...
            'conditionNames', femalePairs{comp}, 'colormap', femaleColors{comp})
        legend off
        set(gca,'XAxisLocation','origin','YAxisLocation','origin')
        Fig.Fix; hold off
        legend(strrep(femalePairs{comp},'_',' '),'Location','bestoutside')
        xlabel(sprintf('ID%d',currIds(1))); ylabel(sprintf('ID%d',currIds(2)))
    end
    if opt.want2save
        figtosave(expName, mainDir, sprintf('DensityMap_ID%d%d', currIds(1), currIds(2)))
    end
end

%% ── 1f. ID statistics — violin plots ───────────────────────────────────────
plotIDViolins(fly, conditionNames, opt, expName, mainDir);

%% ── 1g. Behavior–ID correlation (Hinton / tree plots) ──────────────────────
Statspersonality.hintonMapIDsType(fullTable, opt.n_ids, fly, opt);
title(''); box on; caxis([-1 1]);
ax = gca; ax.YAxisLocation = 'right';
set(gcf,'Units','Inches','Position',[0 0 10 8],'PaperPositionMode','auto');
if opt.want2save, figtosave(expName, mainDir, 'HintonIDs'); end

figure('Name','Tree plots — ID to behavior correlations')
tiledlayout(1, opt.n_ids)
for ids_idx = 1:opt.n_ids
    nexttile
    types = fly.behaveType(fly.lda.table.Properties.VariableNames(opt.datacol:end));
    [~, ~, typeid] = unique(types, 'stable');
    Statspersonality.PlotID2BehaviorNewer( ...
        fly.lda.ids(:, ids_idx), fly.lda.table(:, opt.datacol:end), ...
        'colorBy', typeid, 'verbose', false, ...
        'labels', strrep(fly.lda.table.Properties.VariableNames(opt.datacol:end),'scores',''), ...
        'dict', fly.behaveShortNames, 'align', false, 'max', 15);
    alpha(0.5)
    title(sprintf('ID%d', ids_idx))
    xlim([-.9, .9])
    if opt.want2save
        figtosave(expName, mainDir, sprintf('TreePlot_ID%d', ids_idx))
    end

    % Export correlation table
    t = table( ...
        string(fly.lda.table.Properties.VariableNames(opt.datacol:end))', ...
        fly.behaveShortNames(fly.lda.table.Properties.VariableNames(opt.datacol:end))', ...
        fly.behaveExplain(fly.lda.table.Properties.VariableNames(opt.datacol:end))', ...
        corr(fly.lda.table{:,opt.datacol:end}, fly.lda.ids(:,ids_idx)), ...
        'VariableNames', {'BehaviorCode','ShortName','Explanation','Correlation'});
    writetable(t, fullfile(mainDir, sprintf('ID%d_correlations.csv', ids_idx)));
end

%% ── 1h. LASSO-selected behaviors for natural-language description ────────────
thresh     = 0.90;
min_thresh = 0.10;
filenames  = strings(1, opt.n_ids);
for ids_idx = 1:opt.n_ids
    behav  = fly.lda.table{:, opt.datacol:end};
    id_vec = fly.lda.ids(:, ids_idx);
    [C, p] = corr(behav, id_vec);
    [B, ~] = lasso(behav, id_vec);
    c      = corr(behav * B, id_vec);
    curr_thresh = max(c) * thresh;
    idx    = find(c > curr_thresh, 1, 'last');
    b      = B(:, idx);
    sel    = find(b);
    vnames = string(fly.lda.table.Properties.VariableNames(opt.datacol:end))';
    t      = table( ...
        fly.behaveShortNames(vnames(sel)), C(sel), ...
        fly.behaveExplain(vnames(sel)), p(sel), ...
        'VariableNames', {'Behavior','Correlation','Description','Pvalue'});
    t(t.Pvalue > 0.05 | abs(t.Correlation) < min_thresh, :) = [];
    [~, o] = sort(abs(t.Correlation), 'descend');
    t = t(o, :);
    filenames(ids_idx) = fullfile(mainDir, sprintf('ID%d_lasso.csv', ids_idx));
    writetable(t, filenames(ids_idx));
end
zip(fullfile(mainDir, sprintf('behaviors_lasso_thresh%.2f', thresh)), filenames);

%% ════════════════════════════════════════════════════════════════════════════
%%  SECTION 2 — Social context (familiar vs. unfamiliar partner)
%% ════════════════════════════════════════════════════════════════════════════
close all
expName      = 'SocialContext';
opt.colormap = [255,128,0; 0,204,102] ./ 255;

[fly, fullTable, conditionNames] = loadExperiment(expName, mainDir, meta, opt);
fly = projectOntoW(fly, fullTable, W, opt);

% Density map
ids = [1,2];  N = 500;  nlevels = 7;
xs  = [-.3 .3]; ys = [-.2 .2];
figure('Name','Social context — density map')
conturMesh(fly, ids, N, nlevels, xs, ys, ...
    'conditionNames', conditionNames, 'colormap', opt.colormap)
set(gca,'XAxisLocation','origin','YAxisLocation','origin')
Fig.Fix; xlabel('ID1'); ylabel('ID2')
if opt.want2save, figtosave(expName, mainDir, 'DensityMap'); end

% Violin statistics
plotIDViolins(fly, conditionNames, opt, expName, mainDir);

%% ════════════════════════════════════════════════════════════════════════════
%%  SECTION 3 — Consistency within 30 min (split-half reliability)
%% ════════════════════════════════════════════════════════════════════════════
close all
expName  = 'Rejected30min';
opt_con  = opt;
opt_con.nSegs = 4;

allDatainTbl = loadRawTable(expName, mainDir);
varNames = regexprep(regexprep(allDatainTbl.Properties.VariableNames,'.mat',''),' ','_');
fly_con  = buildFlyStruct(allDatainTbl, meta, opt_con, varNames);

% Project first half (segs 1+2) and second half (segs 3+4) separately.
% Each half covers ~15 min; within-fly distance across halves tests consistency.
y_halves = cell(1,2);
for half = 1:2
    seg_range = (half-1)*2 + (1:2);           % segs 1-2 or segs 3-4
    fullTable_half = vertcat(fly_con.segs(seg_range).table);
    data_half = fullTable_half{:, opt.datacol:end};
    [~, ~, flyidx_half] = unique([fullTable_half.fly, fullTable_half.movie_number],'rows');
    Y = data_half * W;
    y_halves{half} = Q.accumrows(flyidx_half, Y, @mean);
end

% Permutation test: is within-fly distance less than permuted?
figure('Name','Consistency — within 30 min')
ids_to_use = 1:opt.n_ids;
d  = sqrt(sum((y_halves{1}(:,ids_to_use) - y_halves{2}(:,ids_to_use)).^2, 2));
n_perm = 10000;
D = zeros(n_perm, 1);
for i = 1:n_perm
    r    = randperm(size(y_halves{1},1))';
    D(i) = mean(sqrt(sum((y_halves{1}(r,ids_to_use) - y_halves{2}(:,ids_to_use)).^2, 2)));
end
[f, xi] = ksdensity(D);
plot(xi, f, 'LineWidth', 1.5); hold on
xline(mean(d), '--', 'LineWidth', 1.2); hold off
xlabel('Mean Distance'); ylabel('Probability Density')
title('Within-fly consistency (30 min)')
legend('Permuted','Observed','Location','bestoutside')
if opt.want2save, figtosave(expName, mainDir, 'Consistency30min'); end

%% ════════════════════════════════════════════════════════════════════════════
%%  SECTION 4 — Social defeat (winner vs. loser)
%% ════════════════════════════════════════════════════════════════════════════
close all
expName      = 'SocialDefeat';
opt.colormap = [255,0,127; 102,0,102] ./ 255;

[fly, fullTable, conditionNames] = loadExperiment(expName, mainDir, meta, opt);
fly = projectOntoW(fly, fullTable, W, opt);

ids = [1,2];  N = 500;  nlevels = 7;
xs  = [-.3 .3]; ys = [-.2 .2];
figure('Name','Social defeat — density map')
conturMesh(fly, ids, N, nlevels, xs, ys, ...
    'conditionNames', conditionNames, 'colormap', opt.colormap)
set(gca,'XAxisLocation','origin','YAxisLocation','origin')
Fig.Fix; xlabel('ID1'); ylabel('ID2')
if opt.want2save, figtosave(expName, mainDir, 'DensityMap'); end

plotIDViolins(fly, conditionNames, opt, expName, mainDir);

%% ════════════════════════════════════════════════════════════════════════════
%%  SECTION 5 — Microbiome (axenic vs. conventionally reared)
%% ════════════════════════════════════════════════════════════════════════════
close all
expName      = 'Microbiome';
opt.colormap = [34,139,34; 47,79,79; 218,112,214; 138,43,226] ./ 255;

[fly, fullTable, conditionNames] = loadExperiment(expName, mainDir, meta, opt);
fly = projectOntoW(fly, fullTable, W, opt);

% Pair-wise density maps (male and female separately)
ids = [1,2];  N = 500;  nlevels = 7;
xs  = [-.3 .3]; ys = [-.2 .2];

malePairs_mb   = {{'Control_males','Axenic_males'}};
femalePairs_mb = {{'Control_females','Axenic_females'}};
maleColors_mb  = {opt.colormap(1:2,:)};
femaleColors_mb= {opt.colormap(3:4,:)};

figure('Name','Microbiome — density maps')
for comp = 1:1
    subplot(1,2,1)
    conturMesh(fly, ids, N, nlevels, xs, ys, ...
        'conditionNames', malePairs_mb{comp}, 'colormap', maleColors_mb{comp})
    legend off
    set(gca,'XAxisLocation','origin','YAxisLocation','origin'); Fig.Fix; hold off
    legend(strrep(malePairs_mb{comp},'_',' '),'Location','bestoutside')
    xlabel('ID1'); ylabel('ID2')

    subplot(1,2,2)
    conturMesh(fly, ids, N, nlevels, xs, ys, ...
        'conditionNames', femalePairs_mb{comp}, 'colormap', femaleColors_mb{comp})
    legend off
    set(gca,'XAxisLocation','origin','YAxisLocation','origin'); Fig.Fix; hold off
    legend(strrep(femalePairs_mb{comp},'_',' '),'Location','bestoutside')
    xlabel('ID1'); ylabel('ID2')
end
set(gcf,'Units','inches','Position',[0 0 12 3])
if opt.want2save, figtosave(expName, mainDir, 'DensityMap'); end

% All four conditions together
figure('Name','Microbiome — all conditions')
conturMesh(fly, ids, N, nlevels, xs, ys, ...
    'conditionNames', conditionNames, 'colormap', opt.colormap)
legend off
set(gca,'XAxisLocation','origin','YAxisLocation','origin')
set(gcf,'Units','inches','Position',[0 0 8 5]); Fig.Fix; hold off
xlabel('ID1'); ylabel('ID2')
if opt.want2save, figtosave(expName, mainDir, 'DensityMap_All'); end

plotIDViolins(fly, conditionNames, opt, expName, mainDir);

fprintf('\nDone. Figures saved to %s\n', fullfile(mainDir,'Figs'));


%% ════════════════════════════════════════════════════════════════════════════
%%  LOCAL HELPER FUNCTIONS
%% ════════════════════════════════════════════════════════════════════════════

function [fly, fullTable, conditionNames, W] = loadExperiment(expName, mainDir, meta, opt)
%LOADEXPERIMENT  Load a .mat data file, build behavioral metadata, and
%  normalize within-month.  Returns fly struct, concatenated segment table,
%  condition names, and (if present) the W matrix from the opt struct.
    allDatainTbl = loadRawTable(expName, mainDir);
    varNames = regexprep(regexprep( ...
        allDatainTbl.Properties.VariableNames, '.mat', ''), ' ', '_');

    % Build fly struct with behavior metadata dictionaries
    fly = buildFlyStruct(allDatainTbl, meta, opt, varNames);

    % Concatenate both segments into one table
    fullTable = cat(1, fly.segs.table);
    [conditionNames, ~, ~] = unique(fullTable.condition, 'stable');

    W = [];  % caller provides W separately
end


function allDatainTbl = loadRawTable(expName, mainDir)
%LOADRAWTABLE  Load the named experiment .mat and return allDatainTbl.
    s = load(fullfile(mainDir, 'Data', [expName '.mat']));
    allDatainTbl = s.allDatainTbl;
end


function fly = buildFlyStruct(allDatainTbl, meta, opt, varNames)
%BUILDFLYSTRUCT  Compute mean behavioral profiles, build dictionaries, and
%  create within-month-normalized segment tables.
    data = cellfun(@mean, allDatainTbl{:, opt.datacol:end});
    fly.table = [allDatainTbl(:, 1:opt.datacol-1), array2table(data)];
    fly.table.Properties.VariableNames = varNames;

    % Behavior metadata dictionaries
    fly.behaveType       = dictionary(meta.table{1}, meta.type{1});
    fly.behaveShortNames = dictionary(meta.table{1}, meta.text{1});
    fly.behaveExplain    = dictionary(meta.table{1}, meta.explain{1});
    for i = 2:height(meta)
        fly.behaveType(meta.table{i})       = meta.type{i};
        fly.behaveShortNames(meta.table{i}) = meta.text{i};
        fly.behaveExplain(meta.table{i})    = meta.explain{i};
    end
    fly.opt = opt;

    % Split into segments, normalize within month
    fly.segs = struct();
    for seg = 1:opt.nSegs
        data_seg = cellfun(@(x) meanOnSeg(x, opt.nSegs, seg), ...
            allDatainTbl{:, opt.datacol:end});
        data_seg = [allDatainTbl(:, 1:opt.datacol-1), array2table(data_seg)];
        t = normalize(fly, 'month', data_seg);
        t.Properties.VariableNames = varNames;
        fly.segs(seg).table = t;
    end
end


function fly = projectOntoW(fly, fullTable, W, opt)
%PROJECTONTOW  Project behavioral data onto the LDA axes W and store
%  per-fly mean projections in fly.lda.
    data = fullTable{:, opt.datacol:end};
    [~, ~, flyidx]     = unique([fullTable.fly, fullTable.movie_number],'rows');
    [~, ~, conditionIdx] = unique(fullTable.condition, 'stable');

    Y = data * W;
    y = Q.accumrows(flyidx, Y, @mean);

    fly.ids = Y;
    fly.W   = W;
    fly.lda = struct();
    fly.lda.table = fullTable(arrayfun(@(k) find(flyidx==k,1), 1:max(flyidx)), :);
    fly.lda.ids   = y;
end


function plotIDViolins(fly, conditionNames, opt, expName, mainDir)
%PLOTIDVIOLINS  One violin per identity dimension, one panel per condition.
%  Runs permutation ANOVA and overlays significance stars when opt.wantStats.
    ids  = fly.lda.ids;
    cond = fly.lda.table.condition;
    [~, ~, condidx] = unique(cond, 'stable');
    condidnx = unique(condidx, 'stable');
    statRes  = cell(2, opt.n_ids);

    figure('Name', sprintf('%s — ID violin plots', expName), ...
           'Units','Inches','Position',[0 0 12 6])
    for i = 1:opt.n_ids
        id = ids(:, i);
        if opt.norm, id = zscore(id); end

        % Permutation one-way ANOVA
        [p_perm, comparison, gnames] = permutationTestOneWayANOVA(id, cond, 1000);
        fprintf('  %s  ID%d: p = %.4g\n', expName, i, p_perm);

        tblStats = array2table(comparison, 'VariableNames', ...
            {'Group','ControlGroup','LowerLimit','Difference','UpperLimit','Pvalue'});
        tblStats.Group        = gnames(tblStats.Group);
        tblStats.ControlGroup = gnames(tblStats.ControlGroup);
        statRes{1,i} = p_perm;
        statRes{2,i} = tblStats;

        % Save statistics table
        if opt.want2save
            outFile = fullfile(mainDir,'Figs',expName, ...
                sprintf('Stats_ID%d.csv', i));
            writetable(tblStats, outFile);
        end

        subplot(1, opt.n_ids, i); hold on
        vs = violinplot(id, cond, 'GroupOrder', conditionNames, ...
            'QuartileStyle','boxplot','ShowMean',true, ...
            'ViolinColor',opt.colormap,'ViolinAlpha',{0.2 0.9}, ...
            'MarkerSize',2,'ShowMedian',false);
        for j = 1:numel(vs)
            vs(j).MeanPlot.LineWidth = 2;
            vs(j).MeanPlot.Color     = [.3 .3 .3];
        end
        ax = gca; ax.Box = 'off'; ax.TickDir = 'out';
        yline(0,'-','LineWidth',1)
        xlim([xlim() + [-0.3 0.3]])
        if opt.sameScale
            ylim([-0.35 0.3]); yticks(-0.3:0.1:0.3)
        end

        % Significance stars
        if p_perm < 0.05 && opt.wantStats
            p_values   = tblStats.Pvalue;
            grpCompare = num2cell(comparison(:,1:2), 2);
            for ij = 1:numel(p_values)
                if p_values(ij) < 0.05
                    sigstar(grpCompare(ij), p_values(ij))
                end
            end
        end
        xticks(1:numel(condidnx))
        xticklabels(strrep(conditionNames,'_',' '))
        title(sprintf('ID %d', i)); hold off
    end
    if opt.want2save, figtosave(expName, mainDir, 'Violins'); end
end
