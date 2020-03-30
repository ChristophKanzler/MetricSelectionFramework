function metric = generate_simulated_parameter(m, v, num_points, do_log)


rng('default');
%rng(1);
if(do_log)
    mu = log((m^2)/sqrt(v+m^2));
    sigma = sqrt(log(v/(m^2)+1));
    metric = lognrnd(mu,sigma,[num_points,1]);
else
    metric = normrnd(m,v,[num_points,1]);
end
