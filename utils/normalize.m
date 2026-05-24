function nrmlz = normalize(fly, scope, source)
arguments
    fly 
    scope = 'month'
    source = fly.table
end

first_data_col = fly.opt.datacol;
nrmlz = source;
movieNumbers = unique(fly.table.movie_number,"stable");
days = regexprep(fly.table.name_of_the_file, '.*_(\d*)T\d*', '$1');
date = datetime(days, InputFormat='yyyyMMdd');
[~, ~, dayIdx] = unique(days,"stable");

if strcmpi(scope, 'none')
    nrmlz{:, first_data_col:end} = nrmlz{:, first_data_col:end};
elseif strcmpi(scope, 'all')
    nrmlz{:, first_data_col:end} = Q.nwarp(nrmlz{:, first_data_col:end});
elseif strcmpi(scope, 'movie')
    for movieNumber = movieNumbers(:)'
        map = nrmlz.movie_number == movieNumber;
        curr = nrmlz(map, first_data_col:end);
        data = Q.nwarp(table2array(curr));
        nrmlz{map, first_data_col:end} = data;
    end
elseif strcmpi(scope, 'day')
    for day = 1:max(dayIdx)
        map = dayIdx == day;
        curr = nrmlz(map, first_data_col:end);
        data = Q.nwarp(table2array(curr));
        nrmlz{map, first_data_col:end} = data;
    end
elseif strcmpi(scope, 'month')
    filepaths=source.name_of_the_file; 
    months = findmonth(filepaths);
    n_months = unique(months);
    for i = 1:length(n_months)
        map = months==n_months(i);
        % switch i
        %     case 1
        %         map = date < datetime('20220101', InputFormat='yyyyMMdd');
        %     case 2
        %         map = date < datetime('20220701', InputFormat='yyyyMMdd') & ...
        %             date >= datetime('20220101', InputFormat='yyyyMMdd');
        %     case 3
        %         map = date > datetime('20220701', InputFormat='yyyyMMdd');
        % end
        curr = nrmlz(map, first_data_col:end);
        data = Q.nwarp(table2array(curr));
        nrmlz{map, first_data_col:end} = data;
    end
else
    error
end


