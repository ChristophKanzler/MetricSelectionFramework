function metric = generate_simulated_metric(m,v,age)

do_log = 0;
%rng('default');
%rng(1);
constant = zeros(length(age), 1);
for i = 1:length(age)
    if(do_log)
        mu = log((m^2)/sqrt(v+m^2));
        sigma = sqrt(log(v/(m^2)+1));
        constant(i) = lognrnd(mu,sigma,[1,1]);
    else
        constant(i) = normrnd(m,v,[1,1]);
    end
end

metric = abs(constant).*age.^2;