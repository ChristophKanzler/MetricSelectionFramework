function srd_pfenning = get_SRDs(vals_d1,vals_d2,icc_val,percentage_output)

if(abs(icc_val-1) < 1.0000e-6)
    icc_val = 0.999999;
%     display('Reset ICC from 1.0 to 0.99999x for SRD calculation!');
end

sd_x = std([vals_d1(:); vals_d2(:)]);
r_xx =  icc_val;
srd_pfenning = sd_x * sqrt(1-r_xx)*1.96*sqrt(2);

if(~isreal(srd_pfenning))
    error('SRD has an imaginary part! Check that ICC not 1.0');
end
if(percentage_output)
    r =  range(([median(vals_d1,2); median(vals_d2,2)]));
    srd_pfenning = srd_pfenning/r*100;
end
