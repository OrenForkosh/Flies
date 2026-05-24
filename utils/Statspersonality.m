classdef Statspersonality
    methods (Static = true)
        function [p_value_permutation comparison gnames] = permutationTestOneWayANOVA(data,group, numPermutations)
            [observedF,tbl,stats] = anova1(data, group,"off");
            % Initialize an array to store permuted F-statistics
            permutedF = ones(numPermutations, 1);
            % Permutation test
            for i = 1:numPermutations
                % Shuffle the observations among groups
                shuffledData = data(randperm(size(data, 1)));
                % Calculate the F-statistic for the permuted data
                permutedF(i) = anova1(shuffledData, group, 'off');
            end
            % Calculate p-value by comparing observed F-statistic to permuted values
            p_value_permutation = sum(permutedF < observedF) / numPermutations;
            [comparison,~ ,~,gnames] = multcompare(stats, 'CType', 'tukey-kramer');
        end
        %%
        function d = sizeEffectId(ids,groups)
            d={};
            counter =1;
            for ii = 1:max(groups);
                for jj = 1:max(groups);
                    if ii<jj;
                        d{counter,1} = ii;
                        d{counter,2} = jj;
                        d{counter,3} = computeCohen_d(ids(groups==ii), ids(groups==jj));
                        counter=counter+1;
                    end
                end
            end
        end
        function heatMapIDs(allDatainTbl,ids_idx,opt)
            varNames = strrep(allDatainTbl.Properties.VariableNames(opt.datacol:end),"_"," ");
            varNames=strrep(varNames,"scores ","");
            for ii=1:ids_idx
                idsData.(sprintf("ID%d",ii)) = readtable(sprintf("ID%d.csv",ii));
            end
            forheatID={};
            for vm = 1:length(varNames)
                forheatID{vm,1}=varNames(vm);

                for n=2:ids_idx+1

                    forheatID{vm,n}=0;
                    ismatch = strcmp(strrep(idsData.(sprintf("ID%d",n-1)).idsNames1,"scores ",""),varNames(vm));
                    for k=1:length(ismatch)

                        if ismatch(k)

                            forheatID{vm,n}=idsData.(sprintf("ID%d",n-1)).idsNames2(k);
                            % k=length(ismatch);
                            break
                        end
                    end
                end
            end
            %% plotting
            figure
            % Create the dendrogram subplot
            % subplot(1,2,1);
            D = cell2mat(forheatID(:,2:end));
            normalizedData = zscore(D);
            Z = linkage(normalizedData, 'average', 'euclidean');
            [dendroH,~,leafOrder] = dendrogram(Z, 0, 'Orientation', 'left');
            %ylabel('Distance');
            clf;

            % Create the heatmap subplot
            %subplot(1,2,2);
            imagesc(D(leafOrder,:));
            colormap(redblue);
            colorbar;

            % Set x-axis ticks and labels
            ids_idx = size(forheatID, 1);
            set(gca, 'XTick', 1:ids_idx);
            set(gca, 'XTickLabel', cellstr("ID" + (1:ids_idx)));
            xlabel('IDs');

            % Set y-axis ticks and labels
            varNames = varNames(leafOrder); % Update with reordered labels
            set(gca, 'YTick', 1:length(varNames));
            set(gca, 'YTickLabel', varNames);
            ylabel('Variables');

            title('IDs Heatmap');
        end
        %%
        function heatMapIDsType(allDatainTbl,ids_idx,fly,opt)

            varNames = strrep(allDatainTbl.Properties.VariableNames(opt.datacol:end),"_"," ");
            varNames=strrep(varNames,"scores ","");

            types = fly.behaveType(fly.lda.table.Properties.VariableNames(opt.datacol:end));


            [utypes, ~, typeid] = unique(types,"stable");

            shortNames = fly.behaveShortNames(fly.lda.table.Properties.VariableNames(opt.datacol:end));


            for ii=1:ids_idx
                idsData.(sprintf("ID%d",ii)) = readtable(sprintf("ID%d.csv",ii));
            end
            forheatID={};
            for vm = 1:length(varNames)
                forheatID{vm,1}=varNames(vm);

                for n=2:ids_idx+1

                    forheatID{vm,n}=0;
                    ismatch = strcmp(strrep(idsData.(sprintf("ID%d",n-1)).idsNames1,"scores ",""),varNames(vm));



                    k=find(ismatch);
                    if k
                        forheatID{vm,n}=idsData.(sprintf("ID%d",n-1)).idsNames2(k);



                    end
                end
            end
            D = cell2mat(forheatID(:,2:end));
            reorderedD = [];
            reorder = [];
            % Reorder D based on behavior types
            for n = 1:max(typeid)
                % Find the indices of variables of the current type
                currentIndices = find(typeid == n);
                % Append the rows corresponding to these indices to reorderedD
                reorderedD = [reorderedD; D(currentIndices, :)];
                reorder = [reorder;currentIndices];
            end

            % Plot the heatmap with reordered matrix
            figure;

            imagesc(reorderedD);
            colormap(redblue);
            colorbar;

            % Set x-axis ticks and labels
            ids_idx = size(forheatID, 1);
            set(gca, 'XTick', 1:ids_idx);
            set(gca, 'XTickLabel', cellstr("ID" + (1:ids_idx)));

            % Set y-axis ticks and labels
            varNamesReordered = shortNames(reorder); % Assuming varNames is already reordered
            set(gca, 'YTick', 1:length(varNamesReordered));
            set(gca, 'YTickLabel', varNamesReordered);

            title('IDs Heatmap by Behavior Types');
        end

        %%
        function hintonMapIDsType(allDatainTbl, ids_idx, fly, opt)

            varNames = strrep(allDatainTbl.Properties.VariableNames(opt.datacol:end), "_", " ");
            varNames = strrep(varNames, "scores ", "");
            types = fly.behaveType(fly.lda.table.Properties.VariableNames(opt.datacol:end));
            [utypes, ~, typeid] = unique(types, "stable");
            shortNames = fly.behaveShortNames(fly.lda.table.Properties.VariableNames(opt.datacol:end));

            for ii = 1:ids_idx
                idsData.(sprintf("ID%d", ii)) = readtable(sprintf("ID%d.csv", ii));
            end

            forheatID = {};
            for vm = 1:length(varNames)
                forheatID{vm, 1} = varNames(vm);
                for n = 2:ids_idx + 1
                    forheatID{vm, n} = 0;
                    ismatch = strcmp(strrep(idsData.(sprintf("ID%d", n-1)).idsNames1, "scores ", ""), varNames(vm));
                    k = find(ismatch);
                    if ~isempty(k)
                        forheatID{vm, n} = idsData.(sprintf("ID%d", n-1)).idsNames2(k);
                    end
                end
            end
            %%
            t = fly.lda.table(:, allDatainTbl.Properties.VariableNames(opt.datacol:end));
            % torig = fly.table{:, allDatainTbl.Properties.VariableNames(opt.datacol:end)};
            C = 1 - abs(corr(t{:, :}));
            [order, ~, z] = Q.hiersort(C);
            [~, order] = sort(typeid);
            [cb, p] = corr(fly.lda.ids, t{:, :});
            maxVal = max(cb(:));
            labels = fly.behaveShortNames(t.Properties.VariableNames);
            labels = labels(order);
            sortedTypeIDs = typeid(order);
            %
            % subplot(1,4,1)
            % dendrogram(z, length(labels), Reorder=order, Orientation="left"); % , Labels=fly.behaveShortNames(t.Properties.VariableNames)
            % set(gca, 'YDir', 'reverse')
            subplot(1,4,2)
            yy = ylim;
            sig = @(x) tanh(x);

            cb_ = [sig(cb( :, order))'; -[.1 .2 .3]];
            try
                % hinton(cb_, "range", .3, "selection", [p(:, order)' < 0.05; [1 1 1]], "colormap", Colormaps.FromTo([0   177   229] / 255, [1 1 1], [220    73    89] / 255));
                hinton(cb_, "range", .3, "selection", [p(:, order)' < 0.05; [1 1 1]], "colormap", Colormaps.Gradient, "shape", "circle");
            catch
            end
            set(gca, 'YTick', [])
            set(gca, 'YAxisLocation', 'right')
            cmap = [0.8941 0.3686 0.3412; 0.5020 0.6353 0.7922; 0.7647 0.8235 0.3294; 0.8941 0.8471 0.3490];
            for i = 1:length(labels)
                color = cmap(sortedTypeIDs(i), :);
                text(4, i, labels(i), 'Color', color)
            end
            % subplot(1,4,1)
            % ylim(yy);

            %%
          

            D = cell2mat(forheatID(:, 2:end));

            % % only relevant
            % nonEmptyRows = any(D ~= 0, 2) & ~all(isnan(D), 2);
            % D = D(nonEmptyRows, :);
            % varNames = varNames(nonEmptyRows);
            % shortNames = shortNames(nonEmptyRows);
            % typeid = typeid(nonEmptyRows);

            reorderedD = [];
            reorder = [];
            for n = 1:max(typeid)
                currentIndices = find(typeid == n);
                reorderedD = [reorderedD; D(currentIndices, :)];
                reorder = [reorder; currentIndices];
            end
            reorder=flip(reorder);
            reorderedD=flip(reorderedD);
            % figure;
            % clf

            % 
            maxVal = max(abs(reorderedD(:)));

            % if true

            subplot(1,4,4)
            hold on;
            for i = 1:size(reorderedD, 1)
                for j = 1:size(reorderedD, 2)
                    val = reorderedD(i, j);

                    sizeRect = sqrt(abs(val) / maxVal);
                    if val > 0
                        color = [1, 0, 0];
                    elseif val <= 0
                        color = [0, 0, 1];
                    end

                    x = [j - sizeRect / 2, j + sizeRect / 2, j + sizeRect / 2, j - sizeRect / 2];
                    y = [i - sizeRect / 2, i - sizeRect / 2, i + sizeRect / 2, i + sizeRect / 2];

                    fill(x, y, color, 'EdgeColor', 'none', 'FaceAlpha', abs(val) / maxVal);
                end
            end

            axis equal;
            xlim([0, size(reorderedD, 2) + 1]);
            ylim([0, size(reorderedD, 1) + 1]);
            colormap(redblue);
            colorbar;
            % end

            set(gca, 'XTick', 1:size(reorderedD, 2));
            set(gca, 'XTickLabel', cellstr("ID" + (1:ids_idx)), 'FontSize', 10);
            varNamesReordered = shortNames(reorder);
            set(gca, 'YTick', 1:length(varNamesReordered));
            set(gca, 'YTickLabel', varNamesReordered, 'FontSize', 10);

            title('Hinton Diagram of IDs by Behavior Types', 'FontSize', 12);

            hold off;
        end

       
        %%

        function heatMapBs(var)
            condinNames = {'Grouped','Mated','Single'};
            gBS = readtable("G_MvF.csv");
            mBS = readtable("M_MvF.csv");
            sBS = readtable("S_MvF.csv");

            allBehaviors = union(union(gBS.Var1, mBS.Var1), sBS.Var1);

            newTable = table(allBehaviors, 'VariableNames', {'Behavior'});

            [~, locG] = ismember(newTable.Behavior, gBS.Var1);
            newTable.G_Values = zeros(size(newTable, 1), 1);
            newTable.G_Values(locG~=0) = gBS.Var2;

            [~, locM] = ismember(newTable.Behavior, mBS.Var1);
            newTable.M_Values = zeros(size(newTable, 1), 1);
            newTable.M_Values(locM~=0) = mBS.Var2;

            [~, locS] = ismember(newTable.Behavior, sBS.Var1);
            newTable.S_Values = zeros(size(newTable, 1), 1);
            newTable.S_Values(locS~=0) = sBS.Var2;

            % hierarchical clustering
            figure
            D = table2array(newTable(:,2:end));
            normalizedData = zscore(D);
            Z = linkage(normalizedData, 'average', 'euclidean');
            [dendroH,~,leafOrder] = dendrogram(Z, 0);
            clf;

            imagesc(D(leafOrder,:))
            colormap(flip(redbluecmap));
            varNames=table2array(newTable(:,1));
            varNames= strrep(varNames,"_"," ");
            varNames =strrep(varNames,"scores","");
            set(gca, 'XTick', 1:length(condinNames));
            set(gca, 'XTickLabel', condinNames);
            set(gca, 'YTick', 1:size(newTable,1));
            set(gca, 'YTickLabel', varNames(leafOrder));
            title('Behavioral Syndrome heatmap');
        end
        function PlotID2BehaviorNewer(traits, behaviors, opt)
            arguments
                traits
                behaviors table
                opt.onlySignificant = true; % show only significant values
                opt.threshold = [];
                opt.max = [];
                opt.verbose = true;
                opt.markers = [];
                opt.colorBy = [];
                opt.colormap = lines;
                opt.labels = [];
                opt.dict = [];
                opt.align = true
            end
            %%
            if isempty(opt.labels)
                opt.labels = behaviors.Properties.VariableNames;
            end
            %%
            b = table2array(behaviors);
            [c, pval] = Q.nancorr(b, traits);
            N = sum(~isnan(b));

            cmap = flip(Colormaps.BlueWhiteRed, 1);
            corr2color = @(x) cmap(round((-x + 1) * (size(cmap, 1) - 1) / 2 + 1), :);
            if size(traits, 2) > 1
                tiledlayout('flow', 'TileSpacing' , 'loose', 'Padding', 'loose')
            end
            for i = 1:size(traits, 2)
                if size(traits, 2) > 1
                    nexttile;
                end
                [sc, oc] = sort(abs(c(:, i)), 'descend');
                sc = sc .* sign(c(oc, i));
                if ~isempty(opt.markers)
                    markers = opt.markers(oc);
                end
                if ~isempty(opt.colorBy)
                    colorBy = opt.colorBy(oc);
                end
                n = N(oc);
                %%
                names = opt.labels(oc);
                row = 1;
                idsNames ={};
                counterID=1;
                for j = 1:size(behaviors, 2)
                    if isnan(sc(j)) || (opt.onlySignificant  && pval(oc(j), i) > 0.05 / size(behaviors, 2)) || (~isempty(opt.threshold) && abs(sc(j)) < opt.threshold)  || (~isempty(opt.max) && j > opt.max)
                        continue
                    end
                    if ~isempty(opt.colorBy)
                        if colorBy(j) == 0
                            error
                        end
                        Patches.Rect(0, -row, sc(j), .9, opt.colormap(colorBy(j), :), 'EdgeColor', 'none');
                    else
                        Patches.Rect(0, -row, sc(j), .9, corr2color(sc(j)), 'EdgeColor', 'none');
                    end
                    if opt.verbose
                        if sc(j) > 0
                            text(0.9, -row +0.5, sprintf(' %.2g ', sc(j)));%, pval(oc(j), i)));
                            %text(sc(j)*1.3, -row +0.5, sprintf(' %.2g ', sc(j)));%, pval(oc(j), i)));
                        else
                            if opt.align
                            text(-0.9, -row +0.5, sprintf(' %.2g ', sc(j)), 'HorizontalAlignment','right');
                            else
                                text(0.9, -row +0.5, sprintf(' %.2g ', sc(j)));%, pval(oc(j), i)));
                            end
                            %text(sc(j)*1.3, -row +0.5, sprintf(' %.2g ', sc(j)), 'HorizontalAlignment','right');
                        end
                    end
                    hold on
                    %
                    if ~isempty(opt.dict)
                        try
                            name = string(opt.dict(names{j}));
                        catch
                            name = string(strrep(names{j}, '_', ' '));
                        end
                    else
                        name = string(strrep(names{j}, '_', ' '));
                    end
                    name = regexprep(name, '^ *', '');
                    % name = upper(strrep(names{j}, '_', ' '));
                    %                     text(-0.01, -row + .5, name, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'FontName', Theme.FontName)

                    if sc(j) > 0
                        text(0, -row + 0.5, "  " + name, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'left')
                    else
                        if opt.align
                            text(0, -row + 0.5, name + "  ", 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'right')
                        else
                            text(0, -row + 0.5, "  " + name, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'left')
                        end
                    end
                    if ~isempty(opt.markers)
                        plot(max(abs(sc)) * 1.1, -row + .5, 'o', 'MarkerSize', 25, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opt.colormap(markers(j), :));
                        text(max(abs(sc)) * 1.1, -row + .5, num2str(markers(j)), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
                    end
                    row = row + 1;
                    %%% hadar

                    textTitle = sprintf('ID%d', i);
                    idsNames{counterID,1} = name;
                    idsNames{counterID,2} = sc(j);
                    idsNames{counterID,3} = pval(oc(j), i);
                    counterID = counterID+1;
                    %%%
                end
                %%% hadar
                % idsNames ={};
                % counterID=1;
                % textTitle = ['ID'  num2str(i)];
                % idsNames{counterID} = name;
                % counterID = counterID+1;

                % textString = sprintf('%s\n', idsNames{:});
                % % Specify the file name to save the text
                % fileNameTXT = [textTitle,'.txt'];
                % fileNameCSV = [textTitle,'.csv'];
                % 
                % % Open the file for writing
                % fileID = fopen(fileNameTXT, 'w');
                % 
                % % Write the text to the file
                % fprintf(fileID, textString);
                % 
                % % Close the file
                % fclose(fileID);
                %%%
                title(sprintf('ID%d', i))
                % idsNames = cell2table(idsNames);
                % writetable(idsNames,fileNameCSV)
                set(gca, 'YAxisLocation', 'origin', 'YTick', []);
                set(gca, 'XGrid', 'on');
                Fig.Fix;
                hold off
                xlim([-1 1]);
                ylim([-row 1]);
            end

        end
        function [pval final4Galit forallCompare] = BS_compare (mat1,mat2,order,varNames, filename,n1,n2, opt);
            %%
            d1 = 1 - abs(corr(mat1));
            d1 = 1 - d1(order, order);
            d2 = 1 - abs(corr(mat2));
            d2 = 1 - d2(order, order);

            %%
            r1 =d1(:);
            r2 =d2(:);
            pval =[];

            %%
            for ncor = 1:length(r1)
                pval(ncor) = compare_correlation_coefficients(r1(ncor),r2(ncor),n1,n2);
            end

            %%
            pval=reshape(pval,39,39);
            for i = 1:39
                for j = 1:39
                    if i <= j
                        pval(i,j) = NaN;
                    end
                end
            end

            pval=pval(~isnan(pval));
            %% multipulcompare
            [h, crit_p, adj_ci_cvrg, adj_p] = fdr_bh(pval);
            % [q_values, is_significant] = mafdr(pval);

            idxl = tril(true(size(d1)), -1);
            idxl(idxl==1) = h;
            h=idxl.'+idxl;
            h=h(:);


            %%
            figure;
            d1_2 = triu(d1)+tril(d2);
            d1_2(eye(length(d1_2)) == 1) = nan;
            Plot.Hinton(d1_2, range=[0 max(d1_2(:))], colormap=[0.7 0.7 0.7]);
            set(gca, 'XTick', 1:length(d1_2), 'XTickLabel', order)
            set(gca, 'YTick', 1:length(d1_2), 'YTickLabel', order)
            set(gca, 'YTickLabel', strrep(regexprep(varNames(order), '_', ' '),'scores',''), 'YAxisLocation', 'right','FontSize',11)
            set(gca, 'XTickLabel', strrep(regexprep(varNames(order), '_', ' '),'scores',''), 'XAxisLocation', 'bottom','FontSize',11)
            xtickangle(-55);

            hadar = d1-d2;
            rectangleSize=0.8;
            toOutput = [];
            colNames = order;
            rowNames = colNames;
            [rowNamesVector, colNamesVector] = ndgrid(varNames(order), varNames(order));
            % rowColNamesVector = strcat([rowNamesVector(:)+ " VS "], colNamesVector(:));
            rowColNamesVector = [rowNamesVector(:)+ " VS "+ colNamesVector(:)];
            final4Galit={};
            counter=1;
            forallCompare =zeros(39);
            for i = 1:39
                for j = 1:39
                    if h(i*j) %pval(i*j)>0.05
                        if hadar(i, j)>0.15
                            if d1(i,j)>=0.2|d2(i,j)>=0.2
                                if i<j;
                                    rectangleSize=d1(i,j); %%%%%
                                    final4Galit{counter,1} = [rowNamesVector(i,i)  + " vs " + colNamesVector(j,j)];%rowColNamesVector{i*j};
                                    final4Galit{counter,2}= hadar(i, j);
                                    forallCompare(i,j) = d1(i,j);
                                    counter=counter+1;
                                    hold on;
                                    rectangle('Position', [j-rectangleSize/2, i-rectangleSize/2, rectangleSize, rectangleSize], 'EdgeColor', opt.colormapBS.male,'FaceColor', opt.colormapBS.male, 'LineWidth', 1.5);
                                end
                            end
                        elseif hadar(i, j)<-0.15
                            if d1(i,j)>=0.2|d2(i,j)>=0.2
                                if i>j;
                                    rectangleSize=d2(i,j);
                                    final4Galit{counter,1} = [rowNamesVector(i,i)  + " vs " + colNamesVector(j,j)];%rowColNamesVector{i*j};
                                    final4Galit{counter,2} = hadar(i, j);
                                    forallCompare(i,j) = d2(i,j);
                                    counter=counter+1;
                                    hold on;
                                    rectangle('Position', [j-rectangleSize/2, i-rectangleSize/2, rectangleSize, rectangleSize], 'EdgeColor', opt.colormapBS.female,'FaceColor', opt.colormapBS.female, 'LineWidth', 1.5);
                                end
                            end
                        end
                    end

                end
            end
            writecell(final4Galit, filename);
        end
    end
end