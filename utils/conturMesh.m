function conturMesh (fly, ids, N, nlevels,xs,ys, opt)
arguments
    fly
    ids
    N
    nlevels
    xs
    ys
    opt.colormap = [ 0.9529    0.5804    0.3294;0.9922    0.7725    0.2980; 0.6118    0.1569    0.1059; 0.3490    0.4784    0.4314;0.4627    0.7686    0.7059; 0.1137    0.4118    0.6118 ]
    opt.conditionNames = []
    opt.showMean = true
end

[x, y] = meshgrid(linspace(xs(1), xs(2), N), linspace(ys(1), ys(2), N));
pos = [x(:), y(:)];
for idx = 1:length(opt.conditionNames)
    color = opt.colormap(idx, :);
    map = ismember(fly.lda.table.condition,opt.conditionNames{idx});
    f = ksdensity(fly.lda.ids(map, ids), pos);
    f = reshape(f, size(x));
    bw = f > max(f(:))/(nlevels + 1);
    B = bwboundaries(bw);

    for bidx = 1:length(B)
        b = B{bidx};
        p = pos(sub2ind(size(x), b(:, 1), b(:, 2)), :);
        k = convhull(p(:, 1), p(:, 2));
        patch(p(k, 1), p(k, 2), color, 'EdgeColor', color, 'FaceColor', color, 'FaceAlpha', .1, 'LineWidth', 1.25)
        hold on
    end
    hold on
    if opt.showMean
        m = mean(fly.lda.ids(map, ids));
        plot(m(1), m(2), 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', color);
    end
    xlim(xs)
    ylim(ys)
end

