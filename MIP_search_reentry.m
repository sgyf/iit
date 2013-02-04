function [Big_phi_MIP MIP Big_phi_cand MIP_cand BFCut] = MIP_search_reentry(M,N,Big_phi_M,M_IRR_M,prob_M, phi_M,options, concept_MIP_M, network)
%%
% Find the Big-phi MIP in a subset M
% M: a subset where Big_phi_MIP is computed
% N: number of elements in the whole system
% Big_phi_M: Big_phi values in every subset, M
% prob - distributions for the concept for each purview
% phi - phi values for each purview in prob

%%
op_big_phi = options(5);
op_normalize = options(7);
op_console = options(8);

N_M = length(M);

C = [];
for i=1: floor(N_M/2)
    C_temp = nchoosek(M,i);
    if i == floor(N_M/2) && mod(N_M,2) == 0 
        % if M is even only half of the partitions have to be evaluated, the others already appeared 
        % eg. M1 = [1 2] -> M2 = [3 4] doesn't need to be calculated
        N_C = size(C_temp,1)/2;
    else 
        N_C = size(C_temp,1);
    end    
    C = [C; num2cell(C_temp(1:N_C,:),2)];
end   

N_Bp = size(C,1);   %Number of possible PHI partitions

Big_phi_cand = zeros(N_Bp,2);
MIP_cand = cell(N_Bp,1);
M_indexCut = zeros(N_Bp,1);

whole_i = subsystem2index(M);     % Full system index
Big_phi_w = Big_phi_M(whole_i);

phi_whole = phi_M{whole_i}(:,1)';
concept_numind = find(phi_whole ~= 0);
phi_w_concepts = phi_whole(phi_whole ~= 0);
IRR_whole = M_IRR_M{whole_i};

l = 1;
for j = 1:N_Bp
    M1 = C{j};
    M2 = pick_rest(M,M1);

    M1_i = subsystem2index(M1);
    M2_i = subsystem2index(M2);  

    %Big_phi_partition = Big_phi_M(M1_i) + Big_phi_M(M2_i);
    PhiCutSum = [0; 0];  %Larissa: cutting first M1 <- M2 (causes on M1, effects from M2) and then M1 -> M2 (causes on M2, effects from M1)
    if op_big_phi ~= 0
        BRcut_dist = cell(length(phi_w_concepts), 2, 2); %dim1: per concept, dim2: past/future, dim2: whole/cut
        BRcut_phi = zeros(length(phi_w_concepts),1);
        FRcut_dist = cell(length(phi_w_concepts), 2, 2);
        FRcut_phi = zeros(length(phi_w_concepts),1);
    end    
    for k = 1:length(phi_w_concepts)
        IRR_w = IRR_whole{k};
        if all(ismember(IRR_w,M1)) 
            % for M1 <- M2 cut take BR of M1 and FR from M

            indm = concept2index(IRR_w,M1);
            phi_BRcut = min(phi_M{M1_i}(indm,2), phi_M{whole_i}(concept_numind(k),3));
            phi_FRcut = min(phi_M{whole_i}(concept_numind(k),2), phi_M{M1_i}(indm,3));
            if op_big_phi ~= 0 %L1 or Earthmover
                %Larissa: distributions that are identical anyways are empty
    %                         denom_p = sort([concept_MIP_M{M1_i}{indm}{:,1,1}]);
    %                         denom_f = sort([concept_MIP_M{M1_i}{indm}{:,1,2}]);

                cutpdist = expand_prob(prob_M{M1_i,1}{indm}{1},M,M1);
                BRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} cutpdist};
                %compute the max ent forward dist (or the marginal forward) of M2
                forward_max_ent_M2 = comp_pers_cpt(network.nodes,[],M2,[],'forward');
                cutfdist = expand_prob_general(prob_M{M1_i,1}{indm}{2},M,M1,forward_max_ent_M2(:));               
                FRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} cutfdist};
                
                BRcut_phi(k) = phi_BRcut;
                FRcut_phi(k) = phi_FRcut;
                if op_big_phi == 2
                    %Larissa: Maybe more efficient to leave it [] but hopefully doesn't matter much
                    BRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} prob_M{whole_i,1}{concept_numind(k)}{2}}; 
                    FRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} prob_M{whole_i,1}{concept_numind(k)}{1}}; 
                end    
            end    
        elseif all(ismember(IRR_w,M2))

            indm = concept2index(IRR_w,M2);
            phi_BRcut = min(phi_M{whole_i}(concept_numind(k),2), phi_M{M2_i}(indm,3));
            phi_FRcut = min(phi_M{M2_i}(indm,2), phi_M{whole_i}(concept_numind(k),3));
            if op_big_phi ~= 0 %L1 or Earthmover
                %Larissa: distributions that are identical anyways
                %are empty for option 1
    %                         denom_p = sort([concept_MIP_M{M2_i}{indm}{:,1,1}]);
    %                         denom_f = sort([concept_MIP_M{M2_i}{indm}{:,1,2}]); 
    
                %compute the max ent forward dist (or the marginal forward) of M1
                forward_max_ent_M1 = comp_pers_cpt(network.nodes,[],M1,[],'forward');
                cutfdist = expand_prob_general(prob_M{M2_i,1}{indm}{2},M,M2,forward_max_ent_M1(:));
                BRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} cutfdist}; %future might have changed
                cutpdist = expand_prob(prob_M{M2_i,1}{indm}{1},M,M2); 
                FRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} cutpdist}; %back might have changed, future is the same

                BRcut_phi(k) = phi_BRcut;
                FRcut_phi(k) = phi_FRcut;
                if op_big_phi == 2
                    %Larissa: Maybe more efficient to leave it [] but hopefully doesn't matter much
                    BRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} prob_M{whole_i,1}{concept_numind(k)}{1}}; %back is the same
                    FRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} prob_M{whole_i,1}{concept_numind(k)}{2}}; %back might have changed, future is the same
               end 
            end   
        else % if numerator has elements from both sides
            denom_p = sort([concept_MIP_M{whole_i}{concept_numind(k)}{:,1,1}]);    %Larissa: The sort may be important 
            denom_f = sort([concept_MIP_M{whole_i}{concept_numind(k)}{:,1,2}]);
            % for BRcut (M1 <- M2 is cut) M1M2/[M1]p[M2]f is still intact
            BRcut_pdist = []; BRcut_fdist = []; FRcut_pdist = []; FRcut_fdist = []; %Only needed for op_big_phi = 6 or 7
            if all(ismember(denom_p,M1))
                phi_BRcut_BR = phi_M{whole_i}(concept_numind(k),2); %stays the same
                if all(ismember(denom_f,M2))
                    phi_BRcut_FR = phi_M{whole_i}(concept_numind(k),3);
                else
                    % check the new forward phi_mip M1M2/[M1M2]f for all
                    % possible denominators
                    [phi_BRcut_FR, BRcut_fdist, denom_fnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'forward','BRcut');
                end    
            else
                if all(ismember(denom_f,M2))
                    phi_BRcut_FR = phi_M{whole_i}(concept_numind(k),3);
                    % check the new backward phi_mip M1M2/[M1M2]p for all
                    % possible denominators
                    [phi_BRcut_BR, BRcut_pdist, denom_pnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'backward','BRcut');
                else
                    % check the new back and forward phi_mip M1M2/[M1M2]p[M1M2]f for all
                    % possible denominators
                    [phi_BRcut_BR, BRcut_pdist, denom_pnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'backward','BRcut');
                    [phi_BRcut_FR, BRcut_fdist, denom_fnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'forward','BRcut');
                end    
            end

            % for FRcut (M1 -> M2 is cut) M1M2/[M2]p[M1]f is still intact
            if all(ismember(denom_p,M2))
                phi_FRcut_BR = phi_M{whole_i}(concept_numind(k),2); %stays the same
                if all(ismember(denom_f,M1))
                    phi_FRcut_FR = phi_M{whole_i}(concept_numind(k),3);
                else
                    % check the new forward phi_mip M1M2/[M1M2]f for all
                    % possible denominators
                    [phi_FRcut_FR, FRcut_fdist, denom_fnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'forward','FRcut');
                end    
            else
                if all(ismember(denom_f,M1))
                    phi_FRcut_FR = phi_M{whole_i}(concept_numind(k),3);
                    % check the new backward phi_mip M1M2/[M1M2]p for all
                    % possible denominators
                    [phi_FRcut_BR, FRcut_pdist, denom_pnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'backward','FRcut');
                else
                    % check the new back and forward phi_mip M1M2/[M1M2]p[M1M2]f for all
                    % possible denominators
                    [phi_FRcut_BR, FRcut_pdist, denom_pnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'backward','FRcut');
                    [phi_FRcut_FR, FRcut_fdist, denom_fnew, network] = phi_comp_ex_unidir(M,M1,M2,IRR_w,network.current_state,network,'forward','FRcut');
                end    
            end

            %Larissa: if we would want to take op_big_phi into
            %account still, this has to be changed
            phi_BRcut = min(phi_BRcut_BR, phi_BRcut_FR);
            phi_FRcut = min(phi_FRcut_BR, phi_FRcut_FR);
    %                     if phi_BRcut ~= 0
    %                         [M1; M2; IRR_w; denom_p; denom_pnew]
    %                     end
            if op_big_phi ~= 0 %L1 or Earthmover
                if ~isempty(BRcut_pdist)
                    BRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} BRcut_pdist};
                elseif op_big_phi == 2
                    BRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} prob_M{whole_i,1}{concept_numind(k)}{1}};
                end
                if ~isempty(BRcut_fdist)
                    BRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} BRcut_fdist};
                elseif op_big_phi == 2    
                    BRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} prob_M{whole_i,1}{concept_numind(k)}{2}};
                end
                if ~isempty(FRcut_pdist)
                    FRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} FRcut_pdist};
                elseif op_big_phi == 2    
                    FRcut_dist(k,1,:) = {prob_M{whole_i,1}{concept_numind(k)}{1} prob_M{whole_i,1}{concept_numind(k)}{1}};
                end
                if ~isempty(FRcut_fdist)
                    FRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} FRcut_fdist};
                elseif op_big_phi == 2    
                        FRcut_dist(k,2,:) = {prob_M{whole_i,1}{concept_numind(k)}{2} prob_M{whole_i,1}{concept_numind(k)}{2}};
                end

                BRcut_phi(k) = phi_BRcut;
                FRcut_phi(k) = phi_FRcut;
            end   
        end % if 
        PhiCutSum = PhiCutSum + [phi_BRcut; phi_FRcut];
    end %for k 
    [Big_phi_partition, indexCut] = max(PhiCutSum);       % max here means the minimum of the difference between whole and partitioned system   
    
    if op_big_phi == 0
        % 07-06-12 CHANGED TO ABS VALUE
        d_Big_phi = abs(Big_phi_w - Big_phi_partition);
        
    elseif op_big_phi == 1
        back_maxent = expand_prob([],M,[]);
        forward_maxent = comp_pers_cpt(network.nodes,[],M,[],'forward');
        forward_maxent = forward_maxent(:);

        BRcut_Phi = 0;
        FRcut_Phi = 0;
        for k = 1:length(phi_w_concepts)
            if ~isempty(BRcut_dist{k,1,1}) %backward repertoires (if empty they stayed the same!)
                BRcut_Phi = BRcut_Phi + L1norm(BRcut_dist{k,1,1},BRcut_dist{k,1,2})*BRcut_phi(k) + L1norm(BRcut_dist{k,1,1},back_maxent)*(phi_w_concepts(k)-BRcut_phi(k));
            end
            if ~isempty(BRcut_dist{k,2,1}) %forward repertoires
                BRcut_Phi = BRcut_Phi + L1norm(BRcut_dist{k,2,1},BRcut_dist{k,2,2})*BRcut_phi(k) + L1norm(BRcut_dist{k,2,1},forward_maxent)*(phi_w_concepts(k)-BRcut_phi(k));
            end

            if ~isempty(FRcut_dist{k,1,1}) %backward repertoires (if empty they stayed the same!)
                FRcut_Phi = FRcut_Phi + L1norm(FRcut_dist{k,1,1},FRcut_dist{k,1,2})*FRcut_phi(k) + L1norm(FRcut_dist{k,1,1},back_maxent)*(phi_w_concepts(k)-FRcut_phi(k));
            end
            if ~isempty(FRcut_dist{k,2,1}) %forward repertoires
                FRcut_Phi = FRcut_Phi + L1norm(FRcut_dist{k,2,1},FRcut_dist{k,2,2})*FRcut_phi(k) + L1norm(FRcut_dist{k,2,1},forward_maxent)*(phi_w_concepts(k)-FRcut_phi(k));
            end
        end 
        [d_Big_phi, indexCut] = min([BRcut_Phi, FRcut_Phi]);
          
    elseif op_big_phi == 2  %earth movers for concepts
        back_maxent = expand_prob([],M,[]);
        forward_maxent = comp_pers_cpt(network.nodes,[],M,[],'forward');
        forward_maxent = forward_maxent(:);
        
%             indBR = find(BRcut_phi);
%             indFR = find(FRcut_phi);
%             BRcut_phi = BRcut_phi(indBR);
%             FRcut_phi = FRcut_phi(indFR);
%             BRcut_concepts = [BRcut_phi sum(phi_w_concepts)-sum(BRcut_phi)];
%             
%             BRDistMat_past = EMDDistanceMatrix(BRcut_dist(:,1,1), BRcut_dist(indBR,1,2), back_maxent); %past whole and cut distributions
%             BRDistMat_fut = EMDDistanceMatrix(BRcut_dist(:,2,1), BRcut_dist(indFR,2,2), forward_maxent); %future whole and cut distributions
        TempMp = genEMDDistanceMatrix(BRcut_dist(:,1,1), BRcut_dist(:,1,2), back_maxent); %past whole and cut distributions
        BRDistMat_past = [zeros(size(TempMp)), TempMp; TempMp' zeros(size(TempMp))];
        TempMf = genEMDDistanceMatrix(BRcut_dist(:,2,1), BRcut_dist(:,2,2), forward_maxent); %future whole and cut distributions
        BRDistMat_fut = [zeros(size(TempMf)), TempMf; TempMf' zeros(size(TempMf))];

        BRphiDiff = sum(phi_w_concepts)-sum(BRcut_phi);
        tempVphi = [phi_w_concepts'; 0];
        tempVphicut = [BRcut_phi; BRphiDiff];
        BRcut_Phi(1) = emd_hat_gd_metric_mex([tempVphi; zeros(size(tempVphi))],[zeros(size(tempVphicut));tempVphi],BRDistMat_past);
        BRcut_Phi(2) = emd_hat_gd_metric_mex([tempVphi; zeros(size(tempVphi))],[zeros(size(tempVphicut));tempVphi],BRDistMat_fut);
        %BRcut_Phi
        BRcut_Phi = sum(BRcut_Phi); 


        TempMp = genEMDDistanceMatrix(FRcut_dist(:,1,1), FRcut_dist(:,1,2), back_maxent); %past whole and cut distributions
        FRDistMat_past = [zeros(size(TempMp)), TempMp; TempMp' zeros(size(TempMp))];
        TempMf = genEMDDistanceMatrix(FRcut_dist(:,2,1), FRcut_dist(:,2,2), forward_maxent); %future whole and cut distributions
        FRDistMat_fut = [zeros(size(TempMf)), TempMf; TempMf' zeros(size(TempMf))];

        FRphiDiff = sum(phi_w_concepts)-sum(FRcut_phi);

        tempVphicut = [FRcut_phi; FRphiDiff];
        FRcut_Phi(1) = emd_hat_gd_metric_mex([tempVphi; zeros(size(tempVphi))],[zeros(size(tempVphicut));tempVphi],FRDistMat_past);
        FRcut_Phi(2) = emd_hat_gd_metric_mex([tempVphi; zeros(size(tempVphi))],[zeros(size(tempVphicut));tempVphi],FRDistMat_fut);
        %FRcut_Phi
        FRcut_Phi = sum(FRcut_Phi); 

        [d_Big_phi, indexCut] = min([BRcut_Phi, FRcut_Phi]);
        
    elseif op_big_phi == 3
        BRcut_Phi = 0;
        FRcut_Phi = 0;
        for k = 1:length(phi_w_concepts)
            if ~isempty(BRcut_dist{k,1,1}) %backward repertoires (if empty they stayed the same!)
                BRcut_Phi = BRcut_Phi + KLD(BRcut_dist{k,1,1},BRcut_dist{k,1,2});
            end
            if ~isempty(BRcut_dist{k,2,1}) %forward repertoires
                BRcut_Phi = BRcut_Phi + KLD(BRcut_dist{k,2,1},BRcut_dist{k,2,2});
            end

            if ~isempty(FRcut_dist{k,1,1}) %backward repertoires (if empty they stayed the same!)
                FRcut_Phi = FRcut_Phi + KLD(FRcut_dist{k,1,1},FRcut_dist{k,1,2});
            end
            if ~isempty(FRcut_dist{k,2,1}) %forward repertoires
                FRcut_Phi = FRcut_Phi + KLD(FRcut_dist{k,2,1},FRcut_dist{k,2,2});
            end
        end 
        [d_Big_phi, indexCut] = min([BRcut_Phi, FRcut_Phi]);
    end 

    % Norm = min(length(M1),length(M2)) + min(length(M1),length(M2));
    % Norm = 1; % No normalization
    Norm = 2^min(length(M1),length(M2))-1;
    Big_phi_cand(l,1) = d_Big_phi;
    Big_phi_cand(l,2) = d_Big_phi/Norm;
    MIP_cand{l} = M1;
    M_indexCut(l) = indexCut;

%         if N_M == N
%             fprintf('M1=%s-%s: ',mod_mat2str(M1),mod_mat2str(M2));
%             fprintf('%f-(%f+%f)=%f %f\n',Big_phi_w,Big_phi1,Big_phi2,d_Big_phi,d_Big_phi/Norm);
%         end

    l = l + 1;   
end

if (op_normalize == 1 || op_normalize == 2) % Option to normalize or not for new methods of computing big phi
    [min_norm_Big_phi i_phi_min] = min(Big_phi_cand(:,2));
else
    [min_norm_Big_phi i_phi_min] = min(Big_phi_cand(:,1));
end

if (op_normalize == 0 || op_normalize == 1)
    Big_phi_MIP = Big_phi_cand(i_phi_min,1);
else
    Big_phi_MIP = Big_phi_cand(i_phi_min,2);
end

MIP = MIP_cand{i_phi_min};
M2 = pick_rest(M,MIP);
BFCut = M_indexCut(i_phi_min);

if (op_console && Big_phi_MIP ~= 0)
    fprintf('M = %s\nMIP = %s-%s, Big_phi_MIP = %f\n',mat2str(M),mod_mat2str(MIP),mod_mat2str(M2),Big_phi_MIP);
end