function dprime_mat = cl_calcdprime(mat)
%dprime_mat = cl_calcdprime(mat)
%
%This function calculates dprime values from physiology data. dprime is
%computed as the difference between go and nogo stimulus firing rates,
%divided by their common standard deviation.
%
%Input variables:
%       mat:    An Mx3 matrix arranged as follows
%               [stimulus (e.g. AM depth), ave FR, std FR]
%
%ML Caras Dec 2015


%If stim values are in log
if any(mat(:,1) < 0)
    nogo_target = make_stim_log(0);
else
    nogo_target = 0;
end

NOGOmean = mat(mat(:,1) == nogo_target,2);
GOmeans = mat(mat(:,1) ~= nogo_target,2);

NOGOstd = mat(mat(:,1) == nogo_target,3);
GOstds = mat(mat(:,1) ~= nogo_target,3);

%Common std
commonstds = (NOGOstd + GOstds)/2;

%Calculate dprimes
dprimes = (GOmeans-NOGOmean)./commonstds;
dprime_mat = [mat(mat(:,1) ~=nogo_target,1),dprimes];

if any(isnan(dprimes))
   disp catch! 
end

end