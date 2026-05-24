function m = meanOnSeg(x, nsegs, seg)
assert(seg <= nsegs);
d = length(x) / nsegs;
range = floor((seg - 1) * d) + 1:floor(seg * d);
m = mean(x(range));
