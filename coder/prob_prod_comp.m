function prob_prod = prob_prod_comp(prob1,prob2,M,x0_p1,op_fb)
%#codegen
coder.inline('never')

N = length(M);

if nargin < 5
    op_fb = 0;
end

if isempty(prob2) == 1
    prob_prod = prob1;
elseif isempty(prob1) == 1
    prob_prod = prob2;
else
    N1 = length(x0_p1);
    N2 = N - N1;
    x0_p1_or = x0_p1;
    N_vec = 1:N;
    for i=1: N1
        x0_p1(i) = N_vec(M==x0_p1_or(i)); % re-index of x0_p1 in terms of M
    end
    
    x0_p2_test = 1:N2;
    j = 1;
    for i = 1:N
        test = all(x0_p1 ~= i);
        if test
            x0_p2_test(j) = i;
            j = j+1;
        end
    end
        
    
    if op_fb == 3
        prob1_s = reshape(prob1,[2^N1 2^N1]);
        prob2_s = reshape(prob2,[2^N2 2^N2]);
        prob_prod = zeros(2^N,2^N);
        for i = 1:2^N
            xp_bs = trans2(i-1,N);
            xp_bs1 = xp_bs(x0_p1);
            xp_bs2 = xp_bs(x0_p2);
            xp_i1 = trans10(xp_bs1);
            xp_i2 = trans10(xp_bs2);
            for j=1: 2^N
                xf_bs = trans2(j-1,N);
                xf_bs1 = xf_bs(x0_p1);
                xf_bs2 = xf_bs(x0_p2);
                xf_i1 = trans10(xf_bs1);
                xf_i2 = trans10(xf_bs2);
                prob_prod(i,j) = prob1_s(xp_i1,xf_i1)*prob2_s(xp_i2,xf_i2);
            end
        end
        prob_prod = prob_prod(:);
    else
        prob_prod = zeros(2^N,1);
        x0_bs = zeros(N,1);
        for i=1: 2^N1
            x0_bs1 = trans2(i-1,N1);
            x0_bs(x0_p1) = x0_bs1;
            for j=1: 2^N2
                x0_bs2 = trans2(j-1,N2);
                x0_bs(x0_p2) = x0_bs2;
                x0_i = trans10(x0_bs);
                prob_prod(x0_i) = prob1(i)*prob2(j);
            end
        end
        
    end
end