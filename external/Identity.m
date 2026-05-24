classdef Identity
    methods (Static = true)
        function PlotID2Behavior(traits, behaviors, varargin)
            %%
            p = inputParser;
            addParameter(p, 'show', 'sig'); % can be 'all' or 'sig' for only significant values
            addParameter(p, 'sortby', 'abs'); % can be 'abs' or 'val'
            addParameter(p, 'can_be_nan', false); % can be 'abs' or 'val'
            parse(p, varargin{:});
            params = p.Results;
            
            %%
            b = table2array(behaviors);
            if ~params.can_be_nan
                [c, pval] = corr(b, traits);
            else
                [c, pval] = Q.nancorr(b, traits);
            end

            
            cmap = flip(Colormaps.BlueWhiteRed, 1);
            corr2color = @(x) cmap(round((-x + 1) * (size(cmap, 1) - 1) / 2 + 1), :);
            if size(traits, 2) > 1
                tiledlayout('flow', 'TileSpacing' , 'loose', 'Padding', 'loose')
            end

            for i = 1:size(traits, 2)
                if size(traits, 2) > 1
                    nexttile;
                end
                if strcmp(params.sortby, 'abs')
                    [sc, oc] = sort(abs(c(:, i)), 'descend');
                    sc = sc .* sign(c(:, i));
                else
                    [sc, oc] = sort(c(:, i), 'descend');
                end
                %%
                names = behaviors.Properties.VariableNames(oc);
                row = 1;
                for j = 1:size(behaviors, 2)
                    if isnan(sc(j)) || (strcmp(params.show, 'sig') && pval(oc(j), i) > 0.05 / size(behaviors, 2))
                        continue
                    end
                    if strcmp(params.sortby, 'abs')
                        Patches.Rect(0, -row, abs(sc(j)), .9, corr2color(sc(j)), 'EdgeColor', 'none');
                        text(abs(sc(j)), -row + .5, sprintf(' %.2g (p=%.2g)', sc(j), pval(oc(j))));
                    else
                        Patches.Rect(0, -row, sc(j), .9, corr2color(sc(j)), 'EdgeColor', 'none');
                        text(sc(j), -row + .5, sprintf(' %.2g (p=%.2g)', sc(j), pval(oc(j))));
                    end
                    hold on
                    %
                    name = names{j};
                    name = regexprep(name, '_', ' ');
                    name(1) = upper(name(1));
                    text(-0.01, -row + .5, name, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'FontName', Theme.FontName)
                    row = row + 1;
                end
                title(sprintf('ID%d', i))
                set(gca, 'YAxisLocation', 'origin', 'YTick', []);
                Fig.Fix;
                hold off
                if strcmp(params.sortby, 'abs')
                    xlim([0 1]);
                end
                ylim([-row 1]);
            end
            
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
                            text(sc(j), -row + .5, sprintf(' %.2g (%d, p=%.2g)', sc(j), n(j), pval(oc(j), i)));
                        else
                            text(sc(j), -row + .5, sprintf(' %.2g (%d, p=%.2g) ', sc(j), n(j), pval(oc(j), i)), 'HorizontalAlignment','right');
                        end
                    end
                    hold on
                    %
                    name = strrep(names{j}, '_', ' ');
                    % name = upper(strrep(names{j}, '_', ' '));
                    %                     text(-0.01, -row + .5, name, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'FontName', Theme.FontName)
                    if sc(j) > 0
                        text(0, -row + .5, ['  ' name], 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'left')
                    else
                        text(0, -row + .5, [name '  '], 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'HorizontalAlignment', 'right')
                    end
                    if ~isempty(opt.markers)
                        plot(max(abs(sc)) * 1.1, -row + .5, 'o', 'MarkerSize', 25, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opt.colormap(markers(j), :));
                        text(max(abs(sc)) * 1.1, -row + .5, num2str(markers(j)), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
                    end
                    row = row + 1;
                end
                title(sprintf('ID%d', i))
                set(gca, 'YAxisLocation', 'origin', 'YTick', []);
                set(gca, 'XGrid', 'on');
                Fig.Fix;
                hold off
                xlim([-1 1]);
                ylim([-row 1]);
            end
            
        end
        function PlotIDSpaceSimple(traits, labels)
            if size(traits, 2) > 2
                clf
                nc = nchoosek(1:size(traits, 2), 2);
                for i = 1:size(nc, 1)
                    nexttile;
                    Identity.PlotIDSpaceSimple(traits(:, nc(i, :)), labels);
                    xlabel(sprintf('ID%d', nc(i, 1)));
                    ylabel(sprintf('ID%d', nc(i, 2)));
                end
                return;
            end
            %%
            assert(size(traits, 2) == 2);
            [ulables, ~, labelid] = unique(labels);
            %%
            t = Q.accumrows(labelid, traits, @mean, nan);
            t = t - mean(t);

            plot(t(:, 1), t(:, 2), 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','none');
            %%
            hold off
            Fig.Fix
            axis square
            %%
            set(gca, 'YAxisLocation', 'Origin', ...
                'XAxisLocation', 'Origin', ...
                'XTick', [-2 -1 1 2], 'XMinorTick', 'off', ...
                'YTick', [-2 -1 1 2], 'YMinorTick', 'off', ...
                'XTickLabel', {'-2\sigma' '-\sigma' '\sigma' '2\sigma'}, ...
                'YTickLabel', {'-2\sigma' '-\sigma' '\sigma' '2\sigma'});
            xlim(max(abs(xlim)) * [-1 1])
            ylim(max(abs(ylim)) * [-1 1])
        end            

        function PlotIDSpace(traits, labels, varargin)
            if size(traits, 2) > 2
                clf
                nc = nchoosek(1:size(traits, 2), 2);
                for i = 1:size(nc, 1)
                    nexttile;
                    Identity.PlotIDSpace(traits(:, nc(i, :)), labels, varargin{:});
                    xlabel(sprintf('ID%d', nc(i, 1)));
                    ylabel(sprintf('ID%d', nc(i, 2)));
                end
                return;
            end
            %%
            p = inputParser;
            addOptional(p, 'colorby', []);
            addOptional(p, 'markers', []);
            addOptional(p, 'cmap', []);
            addOptional(p, 'means', true);
            addOptional(p, 'znorm', true);
            addOptional(p, 'arcs', []);
            parse(p, varargin{:});
            params = p.Results;
            %%
            assert(size(traits, 2) == 2);
            [ulables, ~, labelid] = unique(labels);
            %%
            if params.znorm
                m = nanmean(Q.accumrows(labelid, traits, @nanmean));
                s = nanstd(Q.accumrows(labelid, traits, @nanmean));
                traits = (traits - m) ./ s;
                try
                    params.arcs = (params.arcs - m) ./ s;
                catch
                end
            end
            %%
            if isempty(params.cmap)
%                 cmap = Colormaps.Random(length(ulables));
                cmap = bone(length(ulables));
                cmap = cmap(randperm(length(ulables)), :);
            else
                cmap = params.cmap;
            end
            if isempty(params.colorby)
                params.colorby = cmap(mod(labelid - 1, size(cmap, 1)) + 1, :);
%                 params.colorby = rand(max(labelid), 3);
            else
                params.colorby = cmap(Q.accumrows(labelid, params.colorby, @mode), :);
            end            
            allmarkers = ['o', '^', 's', 'd', 'p', 'h', '*', '+', '_'];
            if isempty(params.markers)
                params.markers = repmat('o', length(labelid), 1);
            else
                params.markers = allmarkers(Q.accumrows(labelid, params.markers, @mode) + 1);
            end
            %%
            means = zeros(max(ulables), 2);
            for i = 1:max(labelid)
                u = ulables(i);
                map = labels == u;
                t = traits(map, :);
                try
                    ordr = convhull(t(:,1), t(:,2));
                    ch = [t(ordr, 1), t(ordr, 2)];
                catch me
                    if (strcmp(me.identifier,'MATLAB:convhull:NotEnoughPtsConvhullErrId'))
                        ch = [t(:, 1), t(:, 2)];
                    else
                        rethrow(me)
                    end
                end
                means(i, :) = [mean(t(:, 1)), mean(t(:, 2))];
                Patches.Polygon(ch(:, 1), ch(:, 2), params.colorby(i, :), 'EdgeColor', 'none', 'FaceAlpha', .2)
                hold on
            end
            
            if params.means
                for i = 1:max(labelid)
                    plot(means(i, 1), means(i, 2), params.markers(i), 'MarkerFaceColor', params.colorby(i, :), 'MarkerEdgeColor', 'k')
                end
            end
            %
            if ~isempty(params.arcs)
                Patches.Polygon(params.arcs(:, 1), params.arcs(:, 2), 'k', 'FaceColor', 'w', 'FaceAlpha', .2, 'EdgeColor', 'w');
                Patches.Polygon(params.arcs(:, 1), params.arcs(:, 2), 'k', 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 2, 'LineJoin', 'round', 'EdgeAlpha', .75);
                plot(params.arcs(:, 1), params.arcs(:, 2), 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none');
            end
            %%
            hold off
            Fig.Fix
            axis square
            %%
            set(gca, 'YAxisLocation', 'Origin', ...
                'XAxisLocation', 'Origin', ...
                'XTick', [-2 -1 1 2], 'XMinorTick', 'off', ...
                'YTick', [-2 -1 1 2], 'YMinorTick', 'off', ...
                'XTickLabel', {'-2\sigma' '-\sigma' '\sigma' '2\sigma'}, ...
                'YTickLabel', {'-2\sigma' '-\sigma' '\sigma' '2\sigma'});
            xlim(max(abs(xlim)) * [-1 1])
            ylim(max(abs(ylim)) * [-1 1])
            %%
%             Fig.HLine(mean(means(:, 2)), 'LineStyle', '-', 'Color', 'k')
%             Fig.VLine(mean(means(:, 1)), 'LineStyle', '-', 'Color', 'k')
%             axis off
%             Fig.VLine();
        end
        
        function [x, w, y, par, pardist, edgedist, ID, opt] = Compute(tt, opt)
            arguments
                tt table
                %%
                opt.NormalizeBy = @(t) [ Q.getargout(3, @unique, t.GroupType), t.Day];
                opt.IgnoreNan = true;
                opt.Features = 'all';
                opt.Arcs = [];
                opt.W = [];
                opt.UsePareto = false;
            end
            %%
            f = fieldnames(opt);
            Console.WriteLine('setting parameters: ');
            try
                for i=1:length(f)
                    Console.WriteLine(1, '%-20s -> %s', f{i}, Console.Format(opt.(f{i})));
                end
            catch
            end
            %%
            props = Q.cpfield(opt, struct(),  {'Features', 'IgnoreNan', 'NormalizeBy'});
            props = Q.struct2cell(props);
            %%
            %
            Console.Write('loading id file... ');
            load(fullfile(MyFilename.ScriptPath(), 'ID'));
            if ~isempty(opt.W)
                ID.w = opt.W;
            end
            Console.Done;
            [~, t] = Identity.GetProps(true, tt, props{:});

            y = Identity.GetData(false, t, size(ID.w, 2), ID.props);
            x = y * ID.w; 
            w = ID.w; 
            
            %% pareto analysis
            if opt.UsePareto
                if isempty(opt.Arcs)
                    opt.Arcs = ID.Pareto.arc;
                else
                    ID.Pareto.arc = opt.Arcs;
                end

                arc = opt.Arcs;
                if size(arc, 1) ~= 3
                    error
                end
                par = zeros(size(x,1), size(arc, 1));
                for i=1:size(x, 1)
                    par(i,:) = Q.torow(Pareto.PointToCoord(arc, x(i, 1:size(arc, 2))));
                end
                pardist = pdist2(x(:, 1:size(arc, 2)), arc);


                %% pareto edge distance
                %edges = nchoosek(1:3,2);
                edges = [1 2; 2 3; 3 1];
                d = zeros(size(x, 1), size(edges, 1));
                for i=1:size(edges, 1)
                    a = opt.Arcs(edges(i, 1), :) - opt.Arcs(edges(i, 2), :);
                    b = bsxfun(@minus, x(:, 1:size(arc, 2)), opt.Arcs(edges(i, 2), :));
                    for j=1:size(b, 1)
                        d(j, i) = abs(det([b(j, :);a]) ) / norm(a);
                    end
                end
                edgedist.edges = edges;
                edgedist.d = d;
            end
            %%
            
%             par = [];
%             for i = 1:size(arc, 1)
%                 o = 1:size(arc, 1); o(i) = [];
%                 u = (arc(o(2), 2) - arc(o(1), 2)) * x(:, 1) - (arc(o(2), 1) - arc(o(1), 1)) * x(:, 2) - arc(o(2), 2) * arc(o(1), 1);
%                 d = sqrt((arc(o(2), 2) - arc(o(1), 2))^2 + (arc(o(2), 1) - arc(o(1), 1))^2);
%                 u / d
%             end
%             %%
%             arc = [0 0; 0 1; 1 1; 1 0];
%             p = [.5, .5];
%             %p = arc(1, :)
%             plot(arc([1:end 1],1), arc([1:end 1], 2))
%             hold on
%             plot(p(1), p(2), 'o')
%             
%             %
%             
%             for i=1:size(arc, 1)
%                 other = 1:size(arc, 1);
%                 other(i) = [];
%                 x1 = arc(other(1), 1);
%                 y1 = arc(other(1), 2);
%                 x2 = arc(other(2), 1);
%                 y2 = arc(other(2), 2);
%                 x3 = arc(i, 1);
%                 y3 = arc(i, 2);
%                 x4 = p(1);
%                 y4 = p(2);
%                 px = det([det([x1 y1; x2 y2]) det([x1 1; x2 1]); det([x3 y3; x4 y4]) det([x3 1; x4 1])]) / det([det([x1 1; x2 1]) det([y1 1; y2 1]); det([x3 1; x4 1]) det([y3 1; y4 1])]);
%                 py = det([det([x1 y1; x2 y2]) det([y1 1; y2 1]); det([x3 y3; x4 y4]) det([y3 1; y4 1])]) / det([det([x1 1; x2 1]) det([y1 1; y2 1]); det([x3 1; x4 1]) det([y3 1; y4 1])]);
%                 plot([px arc(i, 1)], [py arc(i, 2)], 'o-');
%                 p1 = pdist2(p, [px py]);
%                 p2 = pdist2([x3 y3], [px py]);
%                 coord(i) = p1/p2;
%             end
%             coord = coord / sum(coord);
%             pp = coord * arc;
%             plot(pp(1), pp(2), 'rx', 'MarkerSize', 20)
%             %
%             hold off;
%             %%
%             arc = [0 0; 0 1; 1 1];
%             p = [.8, .2];
%             %p = arc(1, :)
%             plot(arc([1:end 1],1), arc([1:end 1], 2))
%             hold on
%             plot(p(1), p(2), 'o')
%             coord = Pareto.PointToCoord(arc, p);
%             px = coord' * arc;
%             plot(px(1), px(2), 'rx', 'MarkerSize', 25);

%             hold off
        end
        
        function props = HierFeatureSelection(tt, n, labelid, groupid)
            %%
            allprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'ContactRate', 'ContactRateOutside', 'FractionOfTimeInContactOutside', 'MedianContactDuration', 'MeanContactDuration', 'DiffBetweenApproachesAndChases', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfFollowsPerContact', 'FractionOfBeingFollowedPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'AggressiveChaseRateOutside', 'AggressiveEscapeRateOutside', 'FollowRateOutside', 'BeingFollowedRateOutside', 'NAChaseRateOutside', 'NAEscapeRateOutside', 'AggressiveChaseRate', 'AggressiveEscapeRate', 'FollowRate', 'BeingFollowedRate', 'NAChaseRate', 'NAEscapeRate', 'NumberOfApproachs', 'ApproachRateOutside', 'NumberOfApproachesPerCoupleOut', 'NumberOfApproachesPerMiceOut', 'FractionOfApproachesPerContact', 'ApproachRate', 'FractionOfBeingApproachedPerContact', 'BeingApproachedRateOutside', 'BeingApproachedRate', 'FractionOfApproachEscapeBehaviorPerAggression', 'Entropy', 'EntropyOutside', 'FractionOfTimeNearFoodOrWater', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'FractionOfTimeAtHighPlace', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MedianSpeedOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            [~, propidx] = ismember(allprops, tt.Properties.VariableNames);
            proptable = tt(:, propidx);
            data = Q.nwarp(double(table2array(proptable)));
            d = 1 - Q.nancorr(data);
            d(eye(size(d)) > 0) = 0;
            d = (d + d')/2;
            Z = linkage(d);
            c = cluster(Z, n);

            [~, ~, labels] = unique(tt.(labelid));
            [~, ~, groups] = unique(tt.(groupid));
            
            [Sw, Sb] = DimReduction.Scatter(data, labels, groups);
            
            rao = diag(Sb ./ Sw);
            idx = zeros(1, n);
            for i = 1:n
                a = inf(1, length(c));
                a(c == i) = rao(c == i);
                idx(i) = Q.argmin(a);
            end
            props = allprops(idx);
            %%
            
            
            if false
                subplot(2,2,1);
                order = optimalleaforder(Z, d);
                dendrogram(Z, 'labels', tt.Properties.VariableNames(propidx))
                set(gca, 'XTickLabelRotation', -40);
                subplot(2,2,2);
                imagesc((d(order, order)))
                axis square
            end
            
        end
        
        function [props, t, list, tables] = GetProps(normalize, f, varargin)
            %%
            if nargin < 1
                normalize = false;
            end
            %%
            p = inputParser;
            p.addOptional('IgnoreNan', false);
            p.addOptional('short', false);
            p.addOptional('NormalizeBy', 'warp');
            p.addOptional('NormalizeMap', []);
            p.addOptional('n', 20);
            p.addOptional('Features', 'best');
            p.addOptional('Path', [MyFilename.ScriptPath '/../Tables/']);
            p.parse(varargin{:});
            opt = p.Results;
            
            %%
            tables = struct();
            try load([opt.Path, '/EN.mat']);           tables.en = tt;         catch; end
%             try load([opt.Path, '/OTRKO.mat']);        tables.otrko = tt;      catch; end
%             try load([opt.Path, '/OTRWT.mat']);        tables.otrwt = tt;      catch; end
            try load([opt.Path, '/OTR.mat']);        tables.otr = tt;      catch; end
            try load([opt.Path, '/PTSD-full.mat']);         tables.ptsd = tt;       catch; end
            try load([opt.Path, '/OTR.mat']);         tables.otr = tt;       catch; end
            try load([opt.Path, '/OTR.mat']);         tables.otruni = tt; tables.otruni.GroupSubType = tables.otruni.GroupType; for i=1:size(tables.otruni, 1); tables.otruni.GroupType{i} = 'OTR'; end; catch; end
            try load([opt.Path, '/OTR.mat']);         tables.otrtwo = tt; tables.otrtwo.GroupSubType = tables.otrtwo.GroupType; for i=find(~strcmpi(tables.otrtwo.GroupSubType, 'OTRmix'))'; tables.otrtwo.GroupType{i} = 'OTR'; end; catch; end
            try load([opt.Path, '/mousebats.mat']);           tables.mousebats = tt;         catch; end

            try load([opt.Path, '/SC.mat']);           tables.sc = tt;         catch; end
            try load([opt.Path, '/mir182wt.mat']);     tables.mir182wt = tt;   catch; end
            try load([opt.Path, '/mir182ko.mat']);     tables.mir182ko = tt;   catch; end
            try load([opt.Path, '/mdctl.mat']);        tables.mdctl = tt;      catch; end
            try load([opt.Path, '/mdexp.mat']);        tables.mdexp = tt;      catch; end
            try load([opt.Path, '/mdmix.mat']);        tables.mdmix = tt;      catch; end
            try load([opt.Path, '/PersonalityFull.mat']); tables.personalityfull = tt;    catch; end
            try load([opt.Path, '/PersonalityNew.mat']); tables.personalitynew = tt;    catch; end
            try load([opt.Path, '/PersonalityNew2.mat']); tables.personalitynew2 = tt;    catch; end
            try load([opt.Path, '/PersonalityNew3.mat']); tables.personalitynew3 = tt;    catch; end
            try load([opt.Path, '/PersonalityNew3AndBehavior.mat']); tables.personalitynew3andbehave = tt;    catch; end
            try load([opt.Path, '/Mix.mat']);          tables.fullmix = tt;    catch; end
            try load([opt.Path, '/FullMixNew.mat']);          tables.fullmixnew = tt;    catch; end
            try load([opt.Path, '/AlphaOut.mat']);          tables.alphaout = tt;    catch; end
            try 
                load([opt.Path, '/Mix.mat']);
                tt(tt.Day >= 5 | tt.Day <= 0, :) = [];
                tables.mix = tt;
            catch 
            end
            try load([opt.Path, '/Dia.mat']);          tables.dia = tt;        catch; end
            try load([opt.Path, '/Diaind.mat']);       tables.diaind = tt;     catch; end
            try load([opt.Path, '/mix2405.mat']);      tables.newmix = tt;     catch; end
            
            try load([opt.Path, '/Personality.mat']);      
                % remove group 3 of the alpha_out batch (GroupID = 33) -
                % one of the mice died on day 3
                tt(tt.GroupID == 33, :) = []; 
                tables.personality = tt;     catch; end
            
            try load([opt.Path, '/Behavior.mat']);          tables.behavior = tt;        catch; end
            try load([opt.Path, '/Behavior.mat']);          tables.behavior2 = tables.behavior(strcmp(tt.GroupType, 'Behavior2'), :);  tables.behavior2.GroupNumber = tables.behavior2.GroupNumber - min(tables.behavior2.GroupNumber) + 1;
            tables.behavior2.MouseNumber = tables.behavior2.MouseNumber - min(tables.behavior2.MouseNumber) + 1;
            catch; end
            try load([opt.Path, '/AllBehaviors.mat']);      tables.behaviors = tt;        catch; end
            try load([opt.Path, '/HABNAB.mat']);          tables.habnab = tt;        catch; end
            try load([opt.Path, '/with_females.mat']);          tables.with_females = tt;        catch; end
            
            
            
            %%
            if nargin < 2
                f = {'en'     'otr'  'sc', 'mdexp', 'mdctl', 'mdmix', 'ptsd', 'otrwireless'};
                %f = {'en'    'otrko'    'otrwt'  'sc', 'mdexp', 'mdctl', 'mdmix'};
                f = {'mix'};
            end
            
            tables.full = [];
            if istable(f)
                tables.full = f;
            else
                for types = 1:length(f)
                    if ischar(f{types})
                        curr = tables.(f{types});
                    else
                        curr = f{types};
                    end
                    %%
                    curr = Tables.InitIfMissing(curr, 'ConditionID', 1);
                    curr = Tables.InitIfMissing(curr, 'Condition', '');
                    if ~Tables.IsVar(curr, 'ConditionDay')
                        curr.ConditionDay = curr.Day;
                    end
                    %%
                    
                    curr.OriginalGroupType = curr.GroupType;
                    for i=1:size(curr, 1)
                        %curr.GroupType{i} = f{types};
                    end
                    tables.full = CheeseSquare.CombineProfiles(tables.full, curr);
                end
            end            
            %%
            list = containers.Map();
            %
            if opt.short
                list('FractionOfTimeOutside') = {1, '%TimeOutside', 'Outside'};
                list('VisitsOutsideRate') = {1, 'VisitsOutsideRate', 'In/Out-rate'};
                list('EntropyOutside') = {1, 'EntropyOutside', 'Exploration'};
                list('FractionOfTimeNearFoodOrWater') = {1, '%TimeNearFoodOrWater', 'Food/Water'};
                list('MedianSpeedOutside') = {1, 'MedianSpeed', 'Speed'};
                list('MedianContactDuration') = {2, 'ContactDuration', 'Contact-duration'};
                
                list('FractionOfChasesPerContact') = {3, 'Chases/Contact', 'Chase'};
                list('FractionOfEscapesPerContact') = {3, 'Escapes/Contact', 'Escape'};
                list('FractionOfApproachesPerContact') = {2, 'Approaches/Contact', 'Approach'};
                list('FractionOfBeingApproachedPerContact') = {2, 'BeingApproached/Contact', 'Attract'};
                list('ContactRate') = {2, 'ContactRate', 'Contact'};
            else
                list('FractionOfTimeOutside') = {1, '%TimeOutside', 'Outside'};
                list('VisitsOutsideRate') = {1, 'VisitsOutsideRate', 'In/Out-rate'};
                list('Entropy') = {1, 'Entropy', 'Exploration'};
                list('EntropyOutside') = {1, 'EntropyOutside', 'Exploration'};
                list('FractionOfTimeNearFoodOrWater') = {1, '%TimeNearFoodOrWater', 'Food/Water'};
                
                list('MedianSpeedOutside') = {1, 'MedianSpeed', 'Speed'};
                list('DistanceOutside') = {1, 'Distance', 'Distance'};
                list('FoodOrWaterPerTimeOutside') = {1, 'FoodOrWaterPerTimeOutside', 'Food/Water'};
                
                list('HighPlacePerTimeOutside') = {1, 'HighPlacePerTimeOutside', 'High place'};
                list('FractionOfTimeAtHighPlace') = {1, 'FractionOfTimeAtHighPlace', 'High place'};
                
                list('ForagingCorrelation') = {2, 'ForagingCorrelation', 'Foraging'};
                list('FractionOfTimeAloneOutside') = {2, '%AloneOutside', 'Time alone'};
                list('MedianContactDuration') = {2, 'ContactDuration', 'Contact-duration'};
                
                list('FractionOfChasesPerContact') = {3, 'Chases/Contact', 'Chase'};
                list('FractionOfEscapesPerContact') = {3, 'Escapes/Contact', 'Escape'};
                list('FractionOfApproachesPerContact') = {2, 'Approaches/Contact', 'Approach'};
                list('FractionOfBeingApproachedPerContact') = {2, 'BeingApproached/Contact', 'Attract'};
                
                list('ContactRate') = {2, 'ContactRate', 'Contact'};
                list('AggressiveChaseRate') = {3, 'ChaseRate', 'Chase'};
                list('AggressiveEscapeRate') = {3, 'EscapeRate', 'Escape'};
                list('ApproachRate') = {2, 'ApproachRate', 'Approach'};
                list('BeingApproachedRate') = {2, 'BeingApproachedRate', 'Attract'};
            end
            % group:
            group = containers.Map();
            group('GroupGridMultiInfo6x6') = {6, 'GridMultiInfo', 'MultiInfo'};
            group('GroupPotts2nd') = {6, 'Potts2', 'Potts2'};
            group('GroupPotts3rd') = {6, 'Potts3', 'Potts3'};
            group('GroupPotts4th') = {6, 'Potts4', 'MultiInfo'};
            group('GroupForage2nd') = {6, 'Forage2', 'Forage2'};
            group('GroupForage3rd') = {6, 'Forage3', 'Forage3'};
            group('GroupForage4th') = {6, 'Forage2', 'Forage2'};
            if false
                if ismember(group.keys, tables.full.Properties.VariableNames)
                    k = group.keys;
                    for i=1:length(k)
                        list(k{i}) = group(k{i});
                    end
                end
            end
            
            %%
            list = containers.Map();
            list('FractionOfTimeOutside') = {6, 'Out of nest'};
            list('VisitsOutsideRate') = {6, 'Nest exit rate'};
            list('ForagingCorrelation') = {6, 'Foraging correlation'};
            
            %%
            
            allprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'ContactRate', 'ContactRateOutside', 'FractionOfTimeInContactOutside', 'MedianContactDuration', 'MeanContactDuration', 'DiffBetweenApproachesAndChases', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfFollowsPerContact', 'FractionOfBeingFollowedPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'AggressiveChaseRateOutside', 'AggressiveEscapeRateOutside', 'FollowRateOutside', 'BeingFollowedRateOutside', 'NAChaseRateOutside', 'NAEscapeRateOutside', 'AggressiveChaseRate', 'AggressiveEscapeRate', 'FollowRate', 'BeingFollowedRate', 'NAChaseRate', 'NAEscapeRate', 'NumberOfApproachs', 'ApproachRateOutside', 'NumberOfApproachesPerCoupleOut', 'NumberOfApproachesPerMiceOut', 'FractionOfApproachesPerContact', 'ApproachRate', 'FractionOfBeingApproachedPerContact', 'BeingApproachedRateOutside', 'BeingApproachedRate', 'FractionOfApproachEscapeBehaviorPerAggression', 'Entropy', 'EntropyOutside', 'FractionOfTimeNearFoodOrWater', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'FractionOfTimeAtHighPlace', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MedianSpeedOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            allprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'ContactRate', 'ContactRateOutside', 'FractionOfTimeInContactOutside', 'MedianContactDuration', 'MeanContactDuration', 'DiffBetweenApproachesAndChases', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfFollowsPerContact', 'FractionOfBeingFollowedPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'AggressiveChaseRateOutside', 'AggressiveEscapeRateOutside', 'FollowRateOutside', 'BeingFollowedRateOutside', 'NAChaseRateOutside', 'NAEscapeRateOutside', 'AggressiveChaseRate', 'AggressiveEscapeRate', 'FollowRate', 'BeingFollowedRate', 'NAChaseRate', 'NAEscapeRate', 'NumberOfApproachs', 'ApproachRateOutside', 'NumberOfApproachesPerMiceOut', 'FractionOfApproachesPerContact', 'ApproachRate', 'FractionOfBeingApproachedPerContact', 'BeingApproachedRateOutside', 'BeingApproachedRate', 'FractionOfApproachEscapeBehaviorPerAggression', 'Entropy', 'EntropyOutside', 'FractionOfTimeNearFoodOrWater', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'FractionOfTimeAtHighPlace', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MedianSpeedOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            
            
            
            %allprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'ContactRate', 'ContactRateOutside', 'FractionOfTimeInContactOutside', 'MedianContactDuration', 'MeanContactDuration', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfFollowsPerContact', 'FractionOfBeingFollowedPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'AggressiveChaseRateOutside', 'AggressiveEscapeRateOutside', 'FollowRateOutside', 'BeingFollowedRateOutside', 'NAChaseRateOutside', 'NAEscapeRateOutside', 'AggressiveChaseRate', 'AggressiveEscapeRate', 'FollowRate', 'BeingFollowedRate', 'NAChaseRate', 'NAEscapeRate', 'NumberOfApproachs', 'ApproachRateOutside', 'NumberOfApproachesPerMiceOut', 'FractionOfApproachesPerContact', 'ApproachRate', 'FractionOfBeingApproachedPerContact', 'BeingApproachedRateOutside', 'BeingApproachedRate', 'Entropy', 'EntropyOutside', 'FractionOfTimeNearFoodOrWater', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'FractionOfTimeAtHighPlace', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MedianSpeedOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            %allprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'ContactRate', 'ContactRateOutside', 'FractionOfTimeInContactOutside', 'MedianContactDuration', 'MeanContactDuration', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'AggressiveChaseRateOutside', 'AggressiveEscapeRateOutside', 'NAChaseRateOutside', 'NAEscapeRateOutside', 'AggressiveChaseRate', 'AggressiveEscapeRate', 'NAChaseRate', 'NAEscapeRate', 'NumberOfApproachs', 'ApproachRateOutside', 'NumberOfApproachesPerMiceOut', 'FractionOfApproachesPerContact', 'ApproachRate', 'FractionOfBeingApproachedPerContact', 'BeingApproachedRateOutside', 'BeingApproachedRate', 'Entropy', 'EntropyOutside', 'FractionOfTimeNearFoodOrWater', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'FractionOfTimeAtHighPlace', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MedianSpeedOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            bestprops = {'FractionOfApproachesPerContact', 'DistanceFromNest', 'FractionOfTimeNearFoodOrWater', 'BeingFollowedRateOutside', 'FractionOfTimeInContactOutside', 'NAChaseRateOutside', 'FractionOfTimeInWaterOutside', 'EntropyOutside', 'AngularVelocity', 'BeingApproachedRate', 'FractionOfBeingApproachedPerContact', 'MeanContactDuration', 'TangentialVelocity', 'MeanSpeedOutside', 'DistanceFromWallsInOpen', 'FractionOfTimeInSmallNestOutside', 'NumberOfApproachesPerCoupleOut', 'FractionOfFollowsPerContact', 'AggressiveEscapeRateOutside', 'ProximateVsDistantFood', 'FractionOfNAEscapesPerContact', 'FractionOfApproachEscapeBehaviorPerAggression', 'NAEscapeRateOutside', 'FractionOfNAChasesPerContact', 'FractionOfEscapesPerContact', 'BeingApproachedRateOutside', 'MedianSpeedOutside', 'NAEscapeRate'};
            bestprops = {'FractionOfApproachesPerContact', 'DistanceFromNest', 'FractionOfTimeNearFoodOrWater', 'FractionOfNAEscapesPerContact', 'ProximateVsDistantFood', 'NAEscapeRateOutside', 'FractionOfBeingApproachedPerContact', 'NumberOfApproachs', 'ForagingCorrelation', 'BeingFollowedRate', 'DiffBetweenApproachesAndChases', 'ContactRateOutside', 'EntropyOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeInWaterOutside', 'NAChaseRateOutside', 'AngularVelocity', 'TangentialVelocity', 'MeanSpeedOutside', 'MedianSpeedOutside', 'Entropy', 'BeingFollowedRateOutside', 'GridEntropy6x6'};
            essentialprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'NumberOfContactctsPerCoupleOut', 'MeanContactDuration', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'FractionOfApproachesPerContact', 'FractionOfBeingApproachedPerContact', 'EntropyOutside', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside', 'GridEntropy6x6', 'GridMI6x6'};
            
            essentialprops = {'FractionOfTimeOutside', 'VisitsOutsideRate', 'ForagingCorrelation', 'NumberOfContactctsPerCoupleOut', 'MeanContactDuration', 'FractionOfChasesPerContact', 'FractionOfEscapesPerContact', 'FractionOfNAChasesPerContact', 'FractionOfNAEscapesPerContact', 'FractionOfApproachesPerContact', 'FractionOfBeingApproachedPerContact', 'EntropyOutside', 'FoodOrWaterPerTimeOutside', 'FractionOfTimeInFeederOutside', 'FractionOfTimeInWaterOutside', 'ProximateVsDistantFood', 'ProximateVsDistantWater', 'HighPlacePerTimeOutside', 'FractionOfTimeInTheOpenOutside', 'FractionOfTimeInSmallNestOutside', 'FractionOfTimeOnRampOutside', 'FractionOfTimeInLabyrinthOutside', 'DistanceFromWallsInOpen', 'DistanceFromNest', 'FractionOfTimeAloneOutside', 'MeanSpeedOutside', 'TangentialVelocity', 'AngularVelocity', 'DistanceOutside'};
            %bestprops = {'FractionOfApproachesPerContact', 'DistanceFromNest', 'ProximateVsDistantFood', 'BeingFollowedRateOutside', 'FractionOfTimeInContactOutside', 'Entropy', 'TangentialVelocity', 'MeanSpeedOutside', 'AngularVelocity', 'FractionOfFollowsPerContact', 'FractionOfTimeInFeederOutside', 'MedianSpeedOutside', 'FractionOfTimeOutside', 'FractionOfChasesPerContact', 'FractionOfTimeInSmallNestOutside', 'NumberOfApproachesPerCoupleOut', 'MedianContactDuration', 'GridEntropy6x6', 'DistanceFromWallsInOpen', 'AggressiveEscapeRateOutside'};

            %props = list.keys;
            %%
            categories = Identity.Categories();
            %categories();
            
            %%
            switch opt.Features
                case 'all'
                    props = allprops;
                case 'best'
                    %%
                    props = bestprops;
                case 'essential'
                    props = essentialprops;
            end
            
            %%
             list = containers.Map();
             for i=1:length(props)
                 list(props{i}) = categories(props{i}); %{1, props{i}, props{i}};
             end
            %%
            
            t = tables.full;
            if normalize
                [~, propidx] = ismember(props, t.Properties.VariableNames);
                proptable = tables.full(:, propidx(propidx>0));
                orig = double(table2array(proptable));
                if isa(opt.NormalizeMap, 'function_handle')
                    opt.NormalizeMap = opt.NormalizeMap(t);
                end
                if isempty(opt.NormalizeMap)
                    opt.NormalizeMap = true(size(orig, 1), 1);
                end
                data = orig(opt.NormalizeMap, :);
                % normalize tables using warping
                if ischar(opt.NormalizeBy)
                    switch opt.NormalizeBy
                        case {'warp', ''}
                            normdata = Q.nwarp(data);
                        case 'znorm'
                            normdata = Q.znorm(data);
                        case 'none'
                            normdata = data;
                        otherwise
                            normdata = zeros(sum(opt.NormalizeMap), size(proptable, 2));
                            [nrmlzvalue, ~, nrmlz] = unique(tables.full.(opt.NormalizeBy)(opt.NormalizeMap));
                            for i=1:length(nrmlzvalue)
                                normdata(nrmlz == i, :) = Q.nwarp(data(nrmlz == i, :));
                            end
                    end
                else
                    normdata = zeros(sum(opt.NormalizeMap), size(proptable, 2));
                    n = opt.NormalizeBy(tables.full);
                    [nrmlzvalue, ~, nrmlz] = unique(n(opt.NormalizeMap, :), 'rows');
                    for i=1:length(nrmlzvalue)
                        normdata(nrmlz == i, :) = Q.nwarp(data(nrmlz == i, :));
                    end
                end
                if ~isempty(opt.NormalizeMap)
                    newdata = zeros(size(orig));
                    newdata(opt.NormalizeMap, :) = normdata;
                    for i=1:size(data, 2)
                        idx = knnsearch(normdata(:, i), orig(~opt.NormalizeMap, i));
                        newdata(~opt.NormalizeMap, i) = normdata(idx, i);
                    end
                    normdata = newdata;
                end
                
                if ~opt.IgnoreNan && any(isnan(Q.torow(table2array(proptable))))
                    [i,~] = find(sum(isnan(table2array(proptable)), 1));
                    e = proptable.Properties.RowNames(i);
                    error('found NaNs in: %s', sprintf('\n\t%s', e{:}))
                end
                t(:, propidx(propidx>0)) = array2table(normdata);
            end
        end
        
        function RES = CompareAlgorithms(RES)
            [props, tables.full] = Identity.GetProps();
            
            algs = {'rgrouppca', 'fa', 'pca', 'lda', 'baseline'};
            algs = {'ClassicLDA', 'Baseline' ,'FactorAnalysis', 'PCA', 'LDA', 'GroupLDA'};
            %algs = {'LDA', 'GroupLDA', 'ClassicLDA', 'Baseline'};
            %algs = {};
            algs = {'GroupLDA'};
            %algs = {'Baseline'};
            NF = 5;
            aux1 = {};
            aux2 = {};
            TestSize = .2;
            for algidx = 1:length(algs)
                alg = algs{algidx};
                if strcmpi(alg, 'baseline')
                    niters = 1;
                else
                    niters = 50;
                end
                %
                res = [];
                idx = 1;
                Alg = eval(['@Identity.' alg]);
                for nfi=1:length(NF)
                    nf = NF(nfi);
                    Console.Message(1, '%s [%d/%d]: computing for %d/%d factors', alg, algidx,length(algs),  nf, max(NF));
                    for iter=1:niters
                        % split table to two groups
                        [~, ~, groupnum] = unique(tables.full.GroupNumber);
                        r = randperm(max(groupnum));
                        i1 = r(1:floor(end*(1-TestSize)));
                        i2 = r(floor(end*TestSize)+1:end);
                        
                        normtable = tables.full;
                        [~, propidx] = ismember(props, normtable.Properties.VariableNames);
                        proptable = tables.full(:, propidx);
                        %% normalize tables using warping
                        normdata = Q.nwarp(table2array(proptable));
                        normtable(:, propidx) = array2table(normdata);
                        normtable1 = normtable(ismember(groupnum, i1), :);
                        normtable2 = normtable(ismember(groupnum, i2), :);
                        
                        %%
                        try
                            [W1, X1, Y1] = Alg(normtable1, nf, props, aux1{:});
                            [W2, X2, Y2] = Alg(normtable2, nf, props, aux2{:});
                        catch me
                            Console.Warning(me);
                            continue;
                        end
                        res(idx).var = DimReduction.FisherRaoCriterion(bsxfun(@minus, Y2, mean(Y2)) * W1, normtable2.MouseNumber, Q.getargout(3, @unique, normtable2.GroupNumber));
                        %res(idx).var = Identity.FisherRaoCriterion(bsxfun(@minus, Y2, mean(Y2)) * W1, normtable2.MouseNumber, 0*Q.getargout(3, @unique, normtable2.Day)+1);
                        %res(idx).prox = Identity.BaseSimilarity(W1, W2);
                        res(idx).prox = Identity.BaseCorrelation(W1, W2, Y1);
                        %res(idx).recon = mean(sqrt(sum((Q.meannorm(Y1) - X1 * W1').^2, 2)));
                        res(idx).recon = mean(log(Identity.ReconError(W1, Y2, props, normtable2.MouseNumber)));
                        res(idx).autovar = Identity.FisherRaoCriterion(bsxfun(@minus, Y1, mean(Y1)) * W1, normtable1.MouseNumber, normtable1.GroupNumber);
                        res(idx).autorecon = mean(sqrt(sum((Q.meannorm(Y1) - X1 * W1').^2, 2)));
                        res(idx).nf = nf;
                        res(idx).iter = iter;
                        res(idx).models = {i1, i2};
                        idx = idx + 1;
                    end
                end
                RES.(alg) = res;
            end
            Identity.ShowAlgorithms(RES);
        end
        
        function ShowAlgorithms(RES)
            % output
            isrecon = false;
            nftarget = 5;
            algs = fields(RES);
            cmap = lines(length(algs));
            %type = 'auto';
            type = '';
            NF = [];
            for i=1:length(algs)
                %%
                res = RES.(algs{i});
                try
                    NF = union(NF, unique([RES.Baseline.nf]));
                    %% Fisher-Rao
                    subplot(3,Q.ifthen(isrecon, 3, 2),1);
                    range = 1:max([res.nf]);
                    count = histc([res.nf], range);
                    var = struct();
                    var.nf = [res.nf];
                    var.val = [res.([type 'var'])];
                    var.mu  = accumarray(Q.tocol([res.nf]), Q.tocol(var.val), [], @nanmean);
                    var.std = accumarray(Q.tocol([res.nf]), Q.tocol(var.val), [], @std);
                    errorbar(range(count > 0), var.mu(count > 0), var.std(count > 0), 'o-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                    %plot(range(count > 0), var.mu(count > 0), '-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                    hold on
                    %% robustness
                    subplot(3,Q.ifthen(isrecon, 3, 2),2);
                    range = 1:max([res.nf]);
                    count = histc([res.nf], range);
                    prox = struct();
                    prox.nf = [res.nf];
                    prox.val = [res.prox];
                    prox.mu  = accumarray(Q.tocol([res.nf]), Q.tocol(prox.val), [], @nanmean);
                    prox.std = accumarray(Q.tocol([res.nf]), Q.tocol(prox.val), [], @std);
                    errorbar(range(count > 0), prox.mu(count > 0), prox.std(count > 0), 'o-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                    %plot(range(count > 0), prox.mu(count > 0), '-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                    hold on
                    %% reconstruction
                    if isrecon
                        subplot(3,3,3);
                        range = 1:max([res.nf]);
                        count = histc([res.nf], range);
                        recon = struct();
                        recon.nf = [res.nf];
                        recon.val = [res.([type 'recon'])];
                        recon.mu  = accumarray(Q.tocol([res.nf]), Q.tocol([res.([type 'recon'])]), [], @nanmedian);
                        recon.std = accumarray(Q.tocol([res.nf]), Q.tocol([res.([type 'recon'])]), [], @Q.stdR);
                        errorbar(range(count > 0), recon.mu(count > 0), recon.std(count > 0), 'o-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                        %plot(range(count > 0), recon.mu(count > 0), '-', 'Color', cmap(i,:), 'MarkerFaceColor', 'w', 'MarkerEdgeColor', cmap(i, :), 'LineWidth', 2);
                        hold on
                    end
                    %%
                    subplot(3,1,Q.ifthen(isrecon, 2, 2:3));
                    Plot.Scatter(var.mu(range == nftarget), prox.mu(range == nftarget), [], [var.std(range == nftarget), prox.std(range == nftarget)], 'Color', cmap(i,:), 'MarkerEdgeColor', cmap(i,:), 'MarkerFaceColor', cmap(i,:), 'MarkerSize', 8);
                    hold on;
                    if exist('alg', 'var') && strcmpi(alg, algs{i})
                        %    plot(var.mu(range == nftarget), prox.mu(range == nftarget), 'x', 'Color', 'k', 'HandleVisibility', 'off', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
                        plot(var.val(var.nf == nftarget), prox.val(prox.nf == nftarget), '.', 'Color', cmap(i,:), 'HandleVisibility', 'off', 'MarkerFaceColor', cmap(i,:), 'MarkerEdgeColor',cmap(i,:), 'MarkerSize', 8);
                    end
                    
                    %%
                    if isrecon
                        subplot(3,1,3);
                        Plot.Scatter(var.mu(range == nftarget), recon.mu(range == nftarget), [], [var.std(range == nftarget), recon.std(range == nftarget)], 'Color', cmap(i,:), 'MarkerEdgeColor', cmap(i,:), 'MarkerFaceColor', cmap(i,:), 'MarkerSize', 8);
                        hold on;
                    end
                catch
                end
            end
            subplot(3,Q.ifthen(isrecon, 3, 2),1);
            Fig.Title('Fisher criterion');
            set(gca, 'XTick', NF);
            hold off
            subplot(3,Q.ifthen(isrecon, 3, 2),2);
            Fig.Title('Robustness');
            set(gca, 'XTick', NF);
            hold off
            subplot(3,1,Q.ifthen(isrecon, 2, 2:3));
            Fig.Legend(algs, 'Location', 'northeast');
            Fig.Labels('Fisher criterion', 'Robustness');
            hold off
            %axis square
            if isrecon
                subplot(3,3,3);
                Fig.Title('Recon');
                set(gca, 'XTick', NF);
                hold off
                subplot(3,1,3);
                Fig.Legend(algs, 'Location', 'northeast');
                Fig.Labels('Fisher criterion', 'Reconstruction');
                hold off
            end
        end
        
        function d = BaseCorrelation(r1, r2, y)
            x1 = y * r1;
            x2 = y * r2;
            c = abs(corr(x1, x2));
            if size(c,1) < 10
                i2 = perms(1:size(c, 1));
                i1 = repmat(1:size(c, 1), size(i2,1), 1);
                d = 1-max(mean(c(sub2ind(size(c), i1, i2)), 2));
            else
                d = nan;
            end
        end
        
        function ShowBase(x, y, props, w, list)
            %% Show basis
            A = x\y;
            A = A';
            [props, order] = sort(props);
            A = A(order, :);
            if size(A, 1) == length(props) * 2
                subplot(1,2,1);
                %Plot.Hinton([A(1:length(props), :), A(length(props)+1:end, :)]);
                Plot.Hinton(A(index, :));
                a1 = gca;
                a1.Position(1) = 0.05;
                a1.Position(3) = 0.45;
                Fig.Title('Individual');
                set(gca, 'XTick', 1:size(A, 2));
                set(gca, 'YTick', 1:length(props));
                subplot(1,2,2);
                Plot.Hinton(A(length(props)+index, :));
                a2 = gca;
                a2.Position(1) = 0.55;
                a1.Position(3) = 0.45;
                set(gca, 'YTick', 1:length(props), 'YTickLabel', props(:), 'YAxisLocation', 'right');
                set(gca, 'XTick', 1:size(A, 2));
                Fig.Title('Group');
                
                %set(gca, 'YTick', 1:length(props), 'YTickLabel', props, 'YAxisLocation', 'right');
            else
                Plot.Hinton(A);
                set(gca, 'YTick', 1:length(props), 'YTickLabel', props, 'YAxisLocation', 'right');
            end
        end
        
        function ShowCorrelate(x, y, props, list, varargin)
            if nargin < 4
                list = [];
            end
            %%
            p = inputParser;
            p.addOptional('Count', 5);
            p.addOptional('Sep', 5);
            p.addOptional('Radius', .3);
            p.addOptional('Alpha', .05);
            p.addOptional('Indices', []);
            p.addOptional('Dir', 'normal');
            p.addOptional('UseCategories', ~isempty(list));
            p.addOptional('ShowHinton', false);
            p.addOptional('UseClasses', false);
            p.addOptional('IDs', 1:size(x, 2));
            p.parse(varargin{:});
            opt = p.Results;
            %%
            textstyle = {'FontName', 'Open Sans Light', 'FontSize', 16};
            textcolor = {'Color', [.3 .3 .3]};
            %%
            A = [];
            for i=1:size(y, 2)
                valid = ~isnan(y(:, i));
                A(:, i) = x(valid, :)\y(valid, i);
            end
            
            A = A';
            %%
            if opt.UseCategories && isempty(opt.Indices)
                categories = cell(1, length(props));
                for i=1:length(props)
                    categories{i} = cell2mat(Q.getindex(list(props{i}), 2));
                end
                [catnames, ~, catidx] = unique(categories);
                a = Q.accumrows(catidx, A, @(x) x(Q.argmax(abs(x))));
                p = catnames;
            else
                a = A;
                p = props;
            end
            %%
            O = [];
            if isempty(opt.Indices)
                for i=1:size(a, 2)
                    [~, o] = sort(max(abs(a(:, i)), [], 2), 'descend');
                    O = [O; o(1:min(opt.Count, length(o)))];
                end
                O = unique(O);
                a = a(O, :);
                p = p(O);
                %%
                [~, idx] = max(abs(a), [], 2);
                [~, o] = sortrows([idx, -max(abs(a), [], 2)]);
                a = a(o, :);
                p = p(o);
            else
                if ~isempty(list)
                    categories = cell(1, length(props));
                    for i=1:length(props)
                        categories{i} = cell2mat(Q.getindex(list(props{i}), 2));
                    end
                    p = categories;
                end
                a = a(opt.Indices, :);
                p = p(opt.Indices);
            end
            %%
            if false
                [~, o] = sort(max(abs(a), [], 2), 'descend');
                a = a(o(1:opt.Count), :);
                p = p(o(1:opt.Count));
            end
            %%
            [~, ~, clidx] = unique(cellfun(@(x) Q.iftheneval(isempty(x), '', 'x{:}'), regexp(p, '^[^_]*:', 'match'), 'UniformOutput', false));
            classmap = Colormaps.Retro(max(clidx));
            
            if opt.ShowHinton
                %%
                if opt.UseClasses
                    p = regexprep(p, '^[^_]*:', '');
                end
                Plot.Hinton(a, 'colormap', Colormaps.BlueWhiteRed)
                set(gca, 'YTick', 1:size(a,1), 'YTickLabel', p, 'YAxisLocation', 'right', textstyle{:})
                l = {};
                for i=1:size(a,2)
                    l{i} = sprintf('ID%d', i);
                end
                set(gca, 'XTick', 1:size(a,2), 'XTickLabel', l)
            else
                %%
                isnormal = strcmpi(opt.Dir, 'normal');
                factor = 2;
                m = max(abs(a(:)))
                %m = .5;
                linemap = Colormaps.BlueWhiteRed(64);
                [~, rank] = sort(abs(a(:)));
                [J,I] = ind2sub(size(a), rank);
                for i=1:length(rank)
                    w = max(min(a(J(i), I(i)) / m, 1), -1);
                    c = max(min(a(J(i), I(i)) / .7, 1), -1);
                    if ismember(I(i), opt.IDs)
                        Patches.Line([-opt.Sep 0], [size(a, 2)/2*factor - I(i)*factor length(p)/2 - J(i)], abs(w) * opt.Alpha, linemap(round(31 * c + 32), :));
                        hold on;
                    end
                end
                
                cmap = Colormaps.Retro;
                for i=1:size(a, 2)
                    Patches.Circle(-opt.Sep, size(a, 2)/2*factor - i*factor, 1.3*opt.Radius, cmap(i, :));
                    Patches.Text(-opt.Sep, size(a, 2)/2*factor - i*factor, sprintf('ID%d', i), 'Color', 'w', textstyle{:})
                    hold on;
                end
                
                color = [.5 .5 .5];
                for i=1:length(p)
                    %l = list(p{i});
                    %l = l(1);
                    str = p{i};
                    if opt.UseClasses
                        Patches.Circle(0, length(p)/2 - i, opt.Radius, classmap(clidx(i), :));
                        currclass = regexprep(str, ':.*', '');
                        str = regexprep(str, '^[^_]*:', '');
                        text(0, length(p)/2 - i,currclass, textstyle{:}, textcolor{:}, 'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12);
                    else
                        Patches.Circle(0, length(p)/2 - i, opt.Radius, color);
                    end
                    if isnormal
                        text(opt.Radius, length(p)/2 - i,[' ' str], textstyle{:}, textcolor{:});
                    else
                        text(opt.Radius, length(p)/2 - i,[str ' '], textstyle{:}, textcolor{:}, 'HorizontalAlignment', 'right');
                    end
                end
                if ~isnormal
                    set(gca,'xdir','reverse')
                end

                axis equal
                axis off
                hold off;
            end
        end
        
        function ShowAsGraph(x, y, props, list)
            opt.radius = .3;
            opt.d = 5;
            opt.alpha = .05;
            opt.Cluster = true;
            %%
            A = x\y;
            A = A';
            if opt.Cluster
                clustprops = {};
                clustA = [];
                type = [];
                for i=1:length(props)
                    l = list(props{i});
                    tit = l(2); tit = tit{1};
                    idx = find(strcmp(tit, clustprops));
                    if isempty(idx)
                        idx = size(clustA, 1) + 1;
                        clustprops{idx} = tit;
                        clustA(idx, :) = A(i, :);
                    else
                        clustA(idx, :) = clustA(idx, :) + A(i, :);
                    end
                    currtype = l(1);
                    type(idx) = currtype{:};
                end
                props = clustprops;
                [~, idx] = sortrows(table(type(:), props(:)), [1, 2]);
                A = clustA(idx, :);
                props = props(idx);
            end
            %%
            %
            m = max(abs(A(:)));
            %
            cmap = lines(64);
            linemap = Colormaps.BlueWhiteRed(64);
            [~, rank] = sort(abs(A(:)));
            [J,I] = ind2sub(size(A), rank);
            for i=1:length(rank)
                w = A(J(i), I(i)) / m;
                Patches.Line([-opt.d 0], [size(A, 2)/2 - I(i) length(props)/2 - J(i)], abs(w) * opt.alpha, linemap(round(31 * w + 32), :));
                hold on;
            end
            
            for i=1:size(A, 2)
                Patches.Circle(-opt.d, size(A, 2)/2 - i, opt.radius, cmap(i, :));
                Patches.Text(-opt.d, size(A, 2)/2 - i, num2str(i), 'Color', 'w')
                hold on;
            end
            
            for i=1:length(props)
                if opt.Cluster
                    color = Colors.PrettyBlue;
                else
                    l = list(props{i});
                    l = l(1);
                    color = cmap(l{:}, :);
                end
                Patches.Circle(0, length(props)/2 - i, opt.radius, color);
                text(opt.radius, length(props)/2 - i,[' ' props{i}]);
            end
            hold off;
            axis equal
            axis off
        end
        
        
        % Aux
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function p = EquiTest(d1, d2)
            %% statistical test whether the values in d1 and d2 are equal
            valid = ~(isnan(d1) | isnan(d2));
            d1 = d1(valid);
            d2 = d2(valid);
            
            N = 50000;
            count = 1;
            D2 = zeros(N, length(d1));
            while count <= N
                r = randperm(length(d1));
                if any(r == 1:length(d1))
                    continue;
                end
                D2(count, :) = d2(r);
                count = count + 1;
            end
            %
            p = mean(mean((d1 - d2).^2) >= mean(bsxfun(@minus, D2, Q.torow(d1)).^2, 2));
        end
        
        
        % Algorithms
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [W, X, Y] = Baseline(varargin)
            Y = Identity.GetData(false, varargin{:});
            W = eye(size(Y, 2));
            X = Y;
        end
        
        function [W, X, Y] = PenalizedLDA(fulltable, nf, prop, varargin)
            p = inputParser;
            p.addOptional('TrainMap', []);
            p.addOptional('Lambda', .5);
            p.parse(varargin{:});
            opt = p.Results;
            %%
            % W = Identity.GroupLDA(normtable1, nf, Props, Props);
            [~, ~, labels] = unique(fulltable.MouseNumber);
            [~, ~, groups] = unique(fulltable.GroupNumber);
            [~, ~, epochs] = unique(fulltable.Day);
            [~, ~, grtype] = unique(fulltable.GroupType);
            %% extract individual data from table
            [propmap, propidx] = ismember(prop, fulltable.Properties.VariableNames);
            Y = table2array(fulltable(:, propidx));
            if ~isempty(opt.TrainMap)
                map = opt.TrainMap;
            else
                map = true(size(Y, 1), 1);
            end
            %%
            csvwrite('train.csv', Y(map, :));
            csvwrite('label.csv', labels(map, :));
            %%
            exectime = datenum(datevec(now));
            cmd = {};
            cmd{end+1} = 'label = as.matrix(read.table(''label.csv'', sep='',''));';
            cmd{end+1} = 'train = as.matrix(read.table(''train.csv'', sep='',''));';
            cmd{end+1} = 'library(penalizedLDA);';
            cmd{end+1} = sprintf('p = PenalizedLDA(train, label, lambda=%f, K=%d);', opt.Lambda, nf);
            cmd{end+1} = 'write.table(p[1], file = ''plda.csv'', row.names = FALSE, col.names = FALSE, sep = '','' );';
            rcmd = [cmd{:}];
            %rexec = 'rmatlab.bat';
            rscript = 'C:\Program Files\r\R-3.3.1\bin\x64\rscript';
            system(['"' rscript '" -e "' rcmd '"']);
            pldafile = dir('plda.csv');
            if exectime - datenum(pldafile.date) > 1/(24*3600);
                error('file not created');
            end
            W = csvread('plda.csv');
            X = Y * W;
            % train = as.matrix(read.table("ytrain.csv", sep=","))
            % PenalizedLDA(train, label, lambda=.1, K=5)
            % write.table(p[1], sep=",", row.names = FALSE, col.names = FALSE)
            % L=seq(0,1,0.05); for (i in 1:length(L)) { print(sprintf("%d %f", i, L[i])); p = PenalizedLDA(train, label, lambda=L[i], K=5); write.table(p[1], file = sprintf("plda_%.2f.csv", L[i]), row.names = FALSE, col.names = FALSE, sep = "," ) }
            
        end
        
        function [W, X, Y, e, Sw, Sb] = GroupLDA(fulltable, nf, prop, varargin)
            %%
            p = inputParser;
            p.addOptional('RelativeTo', 'all');
            p.addOptional('TrainGroups', {});
            p.addOptional('IsGroup', false);
            p.addOptional('Rotation', 'lda');
            p.addOptional('NormalizeToGroup', false);
            p.addOptional('GroupScale', 1);
            p.addOptional('Algorithm', @DimReduction.LDA);
            p.addOptional('AlgorithmParams', {});
            p.addOptional('TrainMap', []);
            p.addOptional('PCA', 0);
            p.addOptional('IdCol', 'MouseNumber');
            p.addOptional('GroupCol', 'GroupNumber');
            p.addOptional('EpochCol', 'Day');
            p.addOptional('TypeCol', 'GroupType');
            %p.addOptional('Aux', @DimReduction.LDA);
            %              alg = @DimReduction.TraceLDA;
            %
            
            p.parse(varargin{:});
            opt = p.Results;
            %%
            alg = opt.Algorithm;
            if isequal(alg,  @DimReduction.LDA)
                aux = opt.AlgorithmParams;
            elseif isequal(alg,  @DimReduction.TraceLDA)
                aux = {'Rotation', opt.Rotation, opt.AlgorithmParams{:}};
            else
                aux = opt.AlgorithmParams;
            end
            
            %%
            % W = Identity.GroupLDA(normtable1, nf, Props, Props);
            [~, ~, labels] = unique(fulltable.(opt.IdCol));
            [~, ~, groups] = unique(fulltable.(opt.GroupCol));
            [~, ~, epochs] = unique(fulltable.(opt.EpochCol));
            %% extract individual data from table
            [propmap, propidx] = ismember(prop, fulltable.Properties.VariableNames);
            if length(propidx) < length(prop)
                error('could not find in table the following individual variables: %s', sprintf('''%s'' ', prop{propmap}));
            end
            
            if opt.PCA > 0
                orig = table2array(fulltable(:, propidx));
                m = Q.accumrows(labels, orig, @mean);
                Wpca = pca(m,  'NumComponents', opt.PCA);
                %count = sum(cumsum(latent)/sum(latent) <= 2);

               
                %[Wpca,ndata,latent] = pca(orig);
                %data = orig;
                %Wpca = eye(size(orig, 2));
                Yindep = orig * Wpca;
            else
                Yindep = table2array(fulltable(:, propidx));
            end
            %%
            if opt.NormalizeToGroup
                mg = Q.accumrows(groups, Yindep, @mean);
                mg = mg(groups, :);
                Yindep = Yindep - mg;
            end
            
            %% extract group data from table
            if islogical(opt.IsGroup) && opt.IsGroup
                %Ygroupfull = 2*sigmf(Yindep, [10 -0.1])-1;
                Ygroupfull = Yindep;
                Ygroup = zeros(size(Yindep));
                %opt.GroupScale = 2;
                for i=1:size(Ygroupfull, 1)
                    if opt.GroupScale == 1
                        Ygroup(i, :) = mean(Ygroupfull(labels ~= labels(i) & groups == groups(i) & epochs == epochs(i), :));
                    else
                        curr = Ygroupfull(labels ~= labels(i) & groups == groups(i) & epochs == epochs(i), :);
                        %Ygroup(i, :) = mean(sigmf(curr, [.1 0]) - .5);
                        Ygroup(i, :) = mean(sign(curr) .* (abs(curr).^opt.GroupScale));
                        %Ygroup(i, :) = mean(sinh(curr.*opt.GroupScale));
                    end
                end
                Y = [Yindep, Ygroup];
            elseif ~islogical(opt.IsGroup)
                Y = [Yindep, opt.IsGroup];
            else
                Y = Yindep;
            end
            if any(isnan(Y(:)))
                warning('NaN in data table');
            end
            
            %%
            if ~isempty(opt.TrainGroups)
                map = ismember(fulltable.GroupType, opt.TrainGroups);
            elseif ~isempty(opt.TrainMap)
                map = opt.TrainMap;
            else
                map = true(size(Y, 1), 1);
            end
            gb = [];
            if ischar(opt.RelativeTo)
                switch lower(opt.RelativeTo)
                    case {'groupbyday', ''}
                        gb = Q.getargout(3, @unique, [groups(map, :), epochs(map, :)], 'rows');
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
                    case 'day'
                        gb = epochs(map, :);
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
                    case 'group'
                        gb = groups(map, :);
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
                    case 'experiment'
                        [~, ~, grtype] = unique(fulltable.GroupType);
                        gb = grtype(map, :);
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
                    case 'all'
                        gb = [];
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, aux{:});
                    otherwise
                        g = fulltable.(opt.RelativeTo);
                        gb = g(map);
                        [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
                end
            elseif isa(opt.RelativeTo,'function_handle')
                g = opt.RelativeTo(fulltable(map, :));
                gb = g(map);
                [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
            else
                gb = opt.RelativeTo;
                [Wlda, e] = alg(Y(map, :), labels(map, :), nf, 'Groups', gb, aux{:});
            end
            %[e, order] = sort(diag(DimReduction.ScatterBetween(x, 1)) ./ diag(DimReduction.ScatterWithin(x, labels(map, :))), 'descend');
            
            if isa(Wlda, 'function_handle')
                X = Wlda(Y);
            else
                % sorting is only needed is using regularization (like 'gamma')
                x = Y * Wlda;
                if ~isequal(alg,  @DimReduction.GroupPCA)
                    [Sw, Sb] = DimReduction.Scatter(x(map, :), labels(map), gb);
                    %Sb = DimReduction.ScatterBetween(x(map, :), Sw);
                    [e, order] = sort(diag(Sw ./ Sb));
                    Wlda = Wlda(:, order);
                end
                %
                Wlda = bsxfun(@rdivide, Wlda, sqrt(sum(Wlda.^2)));
                X = Y * Wlda;
                %
            end
            
            if opt.PCA > 0
                if islogical(opt.IsGroup) && opt.IsGroup
                    W = [Wpca * Wlda(1:end/2, :); Wpca * Wlda(end/2+1:end, :)];
                elseif ~islogical(opt.IsGroup)
                    W = [Wpca * Wlda(1:end-size(opt.IsGroup, 2), :); Wpca * Wlda(end-size(opt.IsGroup, 2)+1:end, :)];
                else
                    W = Wpca * Wlda;
                end
            else
                W = Wlda;
            end
            
        end
        
%         function [W, X, Y, e] = FactorAnalysis(varargin)
%             [Y, nf] = Identity.GetData(false, varargin{:});
%             [W, e, ~, ~, X] = factoran(Y, nf);
%         end

        function [W, X, Y, e] = FactorAnalysis(tt, nf, props, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('RelativeTo', []);
            p.parse(varargin{:});
            opt = p.Results;
            %%
            [Y, nf] = Identity.GetData(false, tt, nf, props);
            [~, ~, labels] = unique(tt.MouseNumber);
            if isempty(opt.RelativeTo)
            else
                [~, ~, groups] = unique(tt.(opt.RelativeTo));
                m = Q.accumrows(groups, Y, @mean);
                M = m(groups, :);
                Y = Y - M;
            end
            y = Q.accumrows(labels, Y, @mean);
            %[W, e] = DimReduction.PCA(y, nf);
            [W, e, ~, ~, X] = factoran(y, nf);
            
            %%
            X = Y * W;
            %%
%             Y0 = Q.znorm(Y);
%             %X = Y0 / W;
%             sqrtPsi = sqrt(e);
%             invsqrtPsi = diag(1 ./ sqrtPsi);
%             X = (Y0*invsqrtPsi) / (W'*invsqrtPsi);
            %X = bsxfun(@minus, Y, mean(Y)) * W;
        end
        
        function [W, X, Y, e] = PCA(tt, nf, props, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('RelativeTo', []);
            p.parse(varargin{:});
            opt = p.Results;
            %%
            [Y, nf] = Identity.GetData(false, tt, nf, props);
            [~, ~, labels] = unique(tt.MouseNumber);
            if isempty(opt.RelativeTo)
            else
                [~, ~, groups] = unique(tt.(opt.RelativeTo));
                m = Q.accumrows(groups, Y, @mean);
                M = m(groups, :);
                Y = Y - M;
            end
            y = Q.accumrows(labels, Y, @mean);
            [W, e] = DimReduction.PCA(y, nf);
            X = bsxfun(@minus, Y, mean(Y)) * W;
        end
        
        function [W, X, Y, e] = LDA(varargin)
            usepca = false;
            [Y, nf, labels] = Identity.GetData(false, varargin{:});
            if usepca
                [Wpca,ndata,latent] = pca(bsxfun(@minus, Y, mean(Y)));
                idx = sum(cumsum(latent) / sum(latent) < 2);
                Wpca = Wpca(:, 1:idx);
                ndata = ndata(:, 1:idx);
            else
                ndata = bsxfun(@minus, Y, mean(Y));
                Wpca = eye(size(Y, 2));
            end
            [Wlda, e] = DimReduction.TraceLDA(ndata, labels, nf);
            X = ndata * Wlda;
            W = Wpca * Wlda;
            
        end
        
        function [W, X, Y, e] = ClassicLDA(varargin)
            [Y, nf, labels] = Identity.GetData(false, varargin{:});
            [W, e] = DimReduction.LDA(Y, labels, nf);
            
            X = bsxfun(@minus, Y, mean(Y)) * W;
        end
        
        function categories = Categories()
            categories = containers.Map();
            
            categories('FractionOfTimeOutside') = {1, 'Time Outside', ''};
            categories('VisitsOutsideRate') = {1, 'Visits outside rate', ''};
            categories('ForagingCorrelation') = {2, 'Foraging Correlation', ''};
            categories('ContactRate') = {2, 'Contact', ''};
            categories('ContactRateOutside') = {2, 'Contact', ''};
            categories('FractionOfTimeInContactOutside') = {2, 'Time in contact', ''};
            categories('MedianContactDuration') = {2, 'Contact duration', ''};
            categories('MeanContactDuration') = {2, 'Contact duration', ''};
            categories('DiffBetweenApproachesAndChases') = {2, 'Apprach-chase difference', ''};
            categories('FractionOfChasesPerContact') = {2, 'Follow\\Chase', ''};
            categories('FractionOfEscapesPerContact') = {2, 'Lead\\Escape', ''};
            categories('FractionOfFollowsPerContact') = {2, 'Follow\\Chase', ''};
            categories('FractionOfBeingFollowedPerContact') = {2, 'Lead\\Escape', ''};
            categories('FractionOfNAChasesPerContact') = {2, 'Follow\\Chase', ''};
            categories('FractionOfNAEscapesPerContact') = {2, 'Lead\\Escape', ''};
            categories('AggressiveChaseRateOutside') = {2, 'Follow\\Chase', ''};
            categories('AggressiveEscapeRateOutside') = {2, 'Lead\\Escape', ''};
            categories('FollowRateOutside') = {2, 'Follow\\Chase', ''};
            categories('BeingFollowedRateOutside') = {2, 'Lead\\Escape', ''};
            categories('NAChaseRateOutside') = {2, 'Follow\\Chase', ''};
            categories('NAEscapeRateOutside') = {2, 'Lead\\Escape', ''};
            categories('AggressiveChaseRate') = {2, 'Follow\\Chase', ''};
            categories('AggressiveEscapeRate') = {2, 'Lead\\Escape', ''};
            categories('FollowRate') = {2, 'Follow\\Chase', ''};
            categories('BeingFollowedRate') = {2, 'Lead\\Escape', ''};
            categories('NAChaseRate') = {2, 'Follow\\Chase', ''};
            categories('NAEscapeRate') = {2, 'Lead\\Escape', ''};
            categories('NumberOfApproachs') = {2, 'Approach', ''};
            categories('ApproachRateOutside') = {2, 'Approach', ''};
            categories('NumberOfApproachesPerMiceOut') = {2, 'Approach', ''};
            categories('FractionOfApproachesPerContact') = {2, 'Approach', ''};
            categories('ApproachRate') = {2, 'Apprach', ''};
            categories('FractionOfBeingApproachedPerContact') = {2, 'Being approached', ''};
            categories('BeingApproachedRateOutside') = {2, 'Being approached', ''};
            categories('BeingApproachedRate') = {2, 'Being approached', ''};
            categories('FractionOfApproachEscapeBehaviorPerAggression') = {2, 'Approach and escape', ''};
            categories('Entropy') = {1, 'Entropy', ''};
            categories('EntropyOutside') = {1, 'Entropy', ''};
            categories('FractionOfTimeNearFoodOrWater') = {1, 'Food\\Water', ''};
            categories('FoodOrWaterPerTimeOutside') = {1, 'Food\\Water', ''};
            categories('FractionOfTimeInFeederOutside') = {1, 'Food\\Water', ''};
            categories('FractionOfTimeInWaterOutside') = {1, 'Food\\Water', ''};
            categories('ProximateVsDistantFood') = {1, 'Feeder preference', ''};
            categories('ProximateVsDistantWater') = {1, 'Water bottle preference', ''};
            categories('FractionOfTimeAtHighPlace') = {1, 'Elevated area', ''};
            categories('HighPlacePerTimeOutside') = {1, 'Elevated area', ''};
            categories('FractionOfTimeInTheOpenOutside') = {1, 'Open area', ''};
            categories('FractionOfTimeInSmallNestOutside') = {1, 'Small nest', ''};
            categories('FractionOfTimeOnRampOutside') = {1, 'Ramp', ''};
            categories('FractionOfTimeInLabyrinthOutside') = {1, 'S-wall', ''};
            categories('DistanceFromWallsInOpen') = {1, 'Wall distance', ''};
            categories('DistanceFromNest') = {1, 'Nest distance', ''};
            categories('FractionOfTimeAloneOutside') = {2, 'Alone outside', ''};
            categories('MedianSpeedOutside') = {1, 'Speed', ''};
            categories('MeanSpeedOutside') = {1, 'Speed', ''};
            categories('TangentialVelocity') = {1, 'Tangential velocity', ''};
            categories('AngularVelocity') = {1, 'Angular velocity', ''};
            categories('DistanceOutside') = {1, 'Distance', ''};
            categories('GridEntropy6x6') = {1, 'Entropy', ''};
            categories('GridMI6x6') = {1, 'Zone predictability', ''};
        end
        
        function [Y, nf, labels, groups] = GetData(isgroup, fulltable, nf, props)
            [~, ~, labels] = unique(fulltable.MouseNumber);
            [~, ~, groups] = unique(fulltable.GroupNumber);
            [~, ~, epochs] = unique(fulltable.Day);
            
            %% extract individual data from table
            [indepmap, indepidx] = ismember(props, fulltable.Properties.VariableNames);
            if length(indepidx) < length(props)
                error('could not find in table the following individual variables: %s', sprintf('''%s'' ', props{indepmap}));
            end
            Yindep = table2array(fulltable(:, indepidx));
            %% extract group data from table
            if islogical(isgroup) && isgroup
                [groupmap, groupidx] = ismember(props, fulltable.Properties.VariableNames);
                if length(groupidx) < length(props)
                    error('could not find in table the following group variables: %s', sprintf('''%s'' ', props{groupmap}));
                end
                Ygroupfull = table2array(fulltable(:, groupidx));
                Ygroup = zeros(size(Ygroupfull));
                for i=1:size(Ygroupfull, 1)
                    Ygroup(i, :) = mean(Ygroupfull(labels ~= labels(i) & groups == groups(i) & epochs == epochs(i), :));
                end
                %Ygroup = Ygroup - Yindep;
                Y = [Yindep, Ygroup];
            elseif ~islogical(isgroup) && ~isempty(isgroup)
                
                Y = [Yindep, isgroup];
            else
                Y = Yindep;
            end
            if any(isnan(Y(:)))
                warning('NaN in data table');
            end
        end
    end
end