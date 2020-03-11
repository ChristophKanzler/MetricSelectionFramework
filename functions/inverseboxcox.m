function y = inverseboxcox(x,lambda,offset)

if(lambda~=0)
    y = ((x).*lambda+1).^(1/lambda);
else
    y = exp(x);
end

if(nargin==3)
    y = y -offset;
end