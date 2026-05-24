function res = plotIDs(fullTable, idx,opt)
arguments
    fullTable
    idx
    opt.datacol = 6
    opt.projections = true
    opt.n_ids = 5
    opt.colormap = [0 0 0.8;0.2 0.6 1; 0.6 0.8 1; 0.6 0 0;1 0.4 0.4; 1 0.8 0.8 ];
    opt.colorBackgrounds= ones(1, 3)* .7;
    opt.useArch = 0
    opt.conditions = {}
    opt.showAll = false;
    opt.TXT =[]
    opt.W =[]
end
%%
data = fullTable{:, opt.datacol:end};
dataColNames = fullTable.Properties.VariableNames(opt.datacol:end);
[conditionNames, ~, conditionIdx] = unique(fullTable.condition,"stable");
[~, ~, flyidx] = unique([fullTable.fly, fullTable.movie_number], 'rows');
if isempty(opt.W)
    disp("Calculating new W");
    [opt.W, e] = DimReduction.LDA(data, flyidx, opt.n_ids);
end

Y = data * opt.W;
y = Q.accumrows(flyidx, Y, @mean);
short_flyidx = Q.accumrows(flyidx, flyidx, @mean);
condition = Q.accumrows(flyidx, conditionIdx, @mode);
movie_number = Q.accumrows(flyidx, fullTable.movie_number, @mode);
sex = Q.accumrows(flyidx, strcmp(fullTable.sex, 'Males') + 1, @mode);
cmap = opt.colormap;

if opt.useArch > 1
    arch = PCHA1(y(:, idx)', opt.useArch);
    order = convhull(arch');
    arch = arch(:, order)';
end

if opt.projections
    % subplot(5, 5, [2:5, 7:10, 12:15, 17:20]);
    subplot(5, 5, [6:9, 11:14, 16:19, 21:24]);
    % subplot(7, 7, [1:5, 8:12, 15:19, 22:26,29:33]);
    % subplot(7, 7, [3:7, 10:14, 17:21, 24:28,31:35]);
end
%%
prevhold = ishold;
shapes = {'o', 's'};
conditionOrder = 1:max(conditionIdx);
if ~isempty(opt.conditions)
    conditionOrder = [find(~ismember(conditionNames, opt.conditions)); find(ismember(conditionNames, opt.conditions))];
    conditionOrder = conditionOrder(:)';
end
%%
legendValues = struct('label', {}, 'color', {}, 'index', {});
for i = conditionOrder
    if isempty(opt.conditions)
        incat = true;
        color = cmap(i, :);
    else
        if ismember(conditionNames{i}, opt.conditions)
            incat = true;
            color = cmap(i, :);
        else
            incat = false;
            color = opt.colorBackgrounds; %ones(1, 3);% * .7;
        end
    end

    if ~opt.showAll && ~incat
        continue
    end

    %%
    map = condition == i;
    groups = unique(movie_number(map));
    first = true;
    for g = groups(:)'
        currSex = mode(sex(map & movie_number == g));
        if incat && first
            plot(y(map & movie_number == g, idx(1)), y(map & movie_number == g, idx(2)), shapes{currSex}, 'MarkerFaceColor', color, 'MarkerEdgeColor', 'none','MarkerSize', 4);
            legendValues(end+1).label = conditionNames{i};
            legendValues(end).color = color;
            legendValues(end).index = i;
            first = false;
        else
            h = plot(y(map & movie_number == g, idx(1)), y(map & movie_number == g, idx(2)), shapes{currSex}, 'MarkerFaceColor', color, 'MarkerEdgeColor', 'none','HandleVisibility','off','MarkerSize', 4)
        end
        title(opt.TXT);
        hold on

        for curr_fly = short_flyidx(map & movie_number == g)'
            coord = Y(curr_fly == flyidx, :);
            if size(coord, 1) == 2
                plot(coord(:, idx(1)), coord(:, idx(2)), '-', 'Color', color)
            else
                Patches.Polygon(coord(:, idx(1)), coord(:, idx(2)), color, 'FaceAlpha', .1,'HandleVisibility','off');
            end
        end
    end
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'TickDir', 'none', 'MinorGridColor', 'None')

    if opt.projections
        set(gca, 'TickDir', 'out','XTick',[],'XTickLabel',{},'YTick',[],'YTickLabel',{});
    end
    if opt.projections
        if incat
            % subplot(5, 5, [1; 6; 11; 16]);
            subplot(5, 5, [10; 15; 20; 25]);
            % subplot(7, 7, [7; 14; 21;28;35]);
            % subplot(7, 7, [1; 8; 15;22;29]);

            % histogram(y(map, idx(2)), 'FaceColor', color, 'FaceAlpha', 0.5,'orientation','horizontal', 'Normalization', 'probability');
            hold on
            subplot(5, 5, 1:4);
            % subplot(7, 7, 43:47);
            % subplot(7, 7, 45:49);
            % histogram(y(map, idx(1)), 'FaceColor', color, 'FaceAlpha', 0.5, 'Normalization', 'probability');
            hold on
        end
        % subplot(5, 5, [2:5, 7:10, 12:15, 17:20]);
        subplot(5, 5, [6:9, 11:14, 16:19, 21:24]);

        % subplot(7, 7, [1:5, 8:12, 15:19, 22:26,29:33]);
        % subplot(7, 7, [3:7, 10:14, 17:21, 24:28,31:35]);
    end
    if opt.projections
        if incat

            % subplot(5, 5, [1; 6; 11; 16]);
            subplot(5, 5, [10; 15; 20; 25]);

            % subplot(7, 7, [7; 14; 21;28;35]);
            % subplot(7, 7, [1; 8; 15;22;29]);
            [f, xi] = ksdensity(y(map, idx(2)));
            plot(f,xi, 'Color', color, 'LineWidth', 1.5);
            hold on;
            set(gca, 'TickDir', 'out')%,'YAxisLocation','right');
            % set(gca, 'XDir', 'reverse');
            a = get(gca, 'XAxis'); a.Visible = false;
            box off; % Remove box
            mean_val = mean(y(map, idx(2)));
            [~,iii] = min(abs(xi - mean_val));
            plot([0, f(iii)], [mean_val, mean_val], '--', 'Color', color, 'LineWidth', 1.2);
            Fig.Labels("", sprintf('ID%d', idx(2)));
            subplot(5, 5, 1:4);
            % subplot(5, 5, 22:25);
            % subplot(7, 7, 43:47);
            % subplot(7, 7, 45:49);
            [f, xi] = ksdensity(y(map, idx(1)));
            plot(xi, f, 'Color', color, 'LineWidth', 1.5);
            hold on;

            mean_val = mean(y(map, idx(1)));
            [~,iii] = min(abs(xi - mean_val));
            plot([mean_val, mean_val], [0, f(iii)], '--', 'Color', color, 'LineWidth', 1.2);
            %%%%%%%%%%%%%%%%%%%%
            % set(gca, 'YDir', 'reverse'); % Flip the Y-axis
            set(gca, 'TickDir', 'out')%,'XAxisLocation','top');
            a = get(gca, 'YAxis'); a.Visible = false;
            % axis off
            box off; % Remove box
            Fig.Labels(sprintf('ID%d', idx(1)), "");
            %%%%%%%%%%%%%%%%%%
        end

        % subplot(5, 5, [2:5, 7:10, 12:15, 17:20]);
        subplot(5, 5, [6:9, 11:14, 16:19, 21:24]);
        % subplot(7, 7, [1:5, 8:12, 15:19, 22:26,29:33]);
        % subplot(7, 7, [3:7, 10:14, 17:21, 24:28,31:35]);
    end

end
%
if opt.useArch > 1
    plot(arch(:, 1), arch(:, 2), 'k-', 'LineWidth', 2);
end
if ~prevhold
    hold off
end
if ~opt.projections
    Fig.Labels(sprintf('ID%d', idx(1)), sprintf('ID%d', idx(2)));
    set(gca, 'TickDir', 'out')
end
legend(regexprep({legendValues.label}, '_', ' '));
xs = xlim;
ys = ylim;
if opt.projections
    % subplot(5, 5, [1; 6; 11; 16]);
    subplot(5, 5, [10; 15; 20; 25]);
    % subplot(7, 7, [7; 14; 21;28;35]);
    % subplot(7, 7, [1; 8; 15;22;29]);

    hold off
    ylim(ys);

    % subplot(5, 5, 22:25);
    subplot(5, 5, 1:4);

    % subplot(7, 7, 43:47);
    % subplot(7, 7, 45:49);
    hold off
    xlim(xs);

    % subplot(5, 5, [2:5, 7:10, 12:15, 17:20]);
    subplot(5, 5, [6:9, 11:14, 16:19, 21:24]);
    box off
    % subplot(7, 7, [1:5, 8:12, 15:19, 22:26,29:33]);
    % subplot(7, 7, [3:7, 10:14, 17:21, 24:28,31:35]);
end
if nargout > 0
    if opt.useArch > 1
        res.arch = arch;
    end
    res.W = opt.W;
end
