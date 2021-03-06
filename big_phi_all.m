function [Big_phi_M phi_M prob_M subsets MIP_M M_IRR_M network MIP_M_subsys] = big_phi_all(network,whole_sys_state)
%BIG_PHI_ALL
% Compute all candidate systems, compute phi for each one, save results


% compute Big-phi in every possible subset
op_console = network.options(8);
op_parfor = network.options(9); % used by Animat program
op_strongconn = network.options(10);

% "Freezing" external nodes is currently the default
op_extNodes = network.options(11);

% TODO: is this even used? Maybe we skip directly to `big_phi_comp_fb` in
%       `iit_run`?
% Compute the complex (versus just doing the largest subset)
% Involves computing all subsets
op_complex = network.options(3);

N = network.num_nodes; % number of elements in the whole system
nodes_vec = network.full_system;

% subset - build a cell array that contains all of the subsets
% subsets builds arrays that use the actual node numbers as opposed to
% logicals - perhaps we should make one of these that is global as well

% subtract one since we don't consider the empty system
subsets = cell(network.num_states-1,1);
% don't include empty set, this is why for-loop starts at 2
for i = 1:network.num_states-1
    subsets{i} = nodes_vec(logical(network.b_table{i+1,N}));
end

% compute big phi in every possible subset
Big_phi_M = zeros(network.num_states-1,1); % Big_phi for each subset except the empty set
phi_M = cell(network.num_states-1,1);
prob_M = cell(network.num_states-1,2); 
MIP_M = cell(network.num_states-1,1); % the partition that gives Big_phi_MIP for each subset
M_IRR_M = cell(network.num_states-1,1);
% the following is only used for removals but needs to be preallocated for
% possible output anyways.
removal_networks = cell(network.num_states-1,1); 
MIP_M_subsys = cell(network.num_states-1,1); % only used for removals

% If we're not doing a parfor then we compute the BRs and FRs to save them
% for later (otherwise, within the parfor, we can't save them because we
% can't return the `network`).
if op_parfor == 2 && op_extNodes == 0 && op_complex == 1
    network.BRs = cell(network.num_states-1,1); % backward repertoire
    network.FRs = cell(network.num_states-1,1); % forward repertoire
    for i = 1:network.num_states-1
        network.BRs{i} = cell(network.num_subsets); %In principle this could be smaller, but then the indexing gets more complicated later. So now we keep it full system size.
        network.FRs{i} = cell(network.num_subsets);
    end    
end

% With parfor it's probably faster for a single simulation, if many 
% simulations are run in parallel, then it's better to do the for loop 
% which enables the back-passing of network, so BR and FR don't have to be
% calculated in each loop and the Complex Search can later access all the
% distributions in BRs and FRs
% PARALLEL FOR
if op_parfor == 1
    % for all non empty subsets of the system
    parfor sub_index = 1:network.num_states-1 
        this_subset = subsets{sub_index}; % get the subset
        % We skip complex computation if the network isn't strongly
        % connected
        if op_strongconn == 0
            PotIrrComplex = checkStrongCon(this_subset, network);
        else 
            PotIrrComplex = 1;
        end    
        if PotIrrComplex == 1
            % "Removal" is removing the external nodes entirely instead
            % of freezing them
            % `op_extNodes` == 1 means removal instead of freezing
            if op_extNodes == 1 && N ~= numel(this_subset)
                %Put an extra thing into network with the new connectivity
                %matrices and the new nodes for each subset
                
                % Define removal behavior
                removal_networks{sub_index} = cpt_removal_network(this_subset,network);
                % Compute `big_phi_comp_fb` with `removal_networks` instead of
                % the current subset
                [Big_phi, phi, prob_cell, MIP, M_IRR] = big_phi_comp_fb(removal_networks{sub_index}.full_system,whole_sys_state,removal_networks{sub_index}); 
                % 
                MIP_M_subsys{sub_index} = MIP_subsys_nodes(MIP,this_subset);
            else
                % Parallel for cannot output `network`
                % Output:
                % Total phi, matrix of small phis ([[min, past, future]]),
                % used in making labels at end, numerators of all
                % irreducible concepts
                [Big_phi, phi, prob_cell, MIP, M_IRR] = big_phi_comp_fb(this_subset,whole_sys_state,network); 
            end 
            % Save results:
            % For all subsets, save the collection of MIPs
            MIP_M{sub_index} = MIP;
            % Big_phi for each subset
            Big_phi_M(sub_index) = Big_phi;
            % Set of small_phis for each purview of each subset
            phi_M{sub_index} = phi;
            % numerators of purviews with non-zero/positive phi
            M_IRR_M{sub_index} = M_IRR;
            % concept distributions
            prob_M(sub_index,:) = prob_cell(:); % first layer is subset, second is purview, third is backward/forward
        end  
    end
else
% SEQUENTIAL FOR
    for sub_index = 1:network.num_states-1 % for all non empty subsets of the system
        this_subset = subsets{sub_index}; % get the subset
        if op_strongconn == 0
            PotIrrComplex = checkStrongCon(this_subset, network);
        else 
            PotIrrComplex = 1;
        end  
        if PotIrrComplex == 1
            if op_extNodes == 1 && N ~= numel(this_subset)
                %Put an extra thing into network with the new connectivity
                %matrices and the new nodes for each subset
                removal_networks{sub_index} = cpt_removal_network(this_subset,network);
                [Big_phi phi prob_cell MIP M_IRR removal_networks{sub_index}] = big_phi_comp_fb(removal_networks{sub_index}.full_system,whole_sys_state,removal_networks{sub_index}); 
                MIP_M_subsys{sub_index} = MIP_subsys_nodes(MIP,this_subset);
            else
                % Sequential version can output modified `network`
                [Big_phi phi prob_cell MIP M_IRR network] = big_phi_comp_fb(this_subset,whole_sys_state,network); 
            end  
            MIP_M{sub_index} = MIP;
            Big_phi_M(sub_index) = Big_phi; % Big_phi for each subset
            phi_M{sub_index} = phi; % Set of small_phis for each purview of each subset
            M_IRR_M{sub_index} = M_IRR; % numerators of purviews with non-zero/positive phi
            % concept distributions
            prob_M(sub_index,:) = prob_cell(:); % first layer is subset, second is purview, third is backward/forward  
            %save('OizumiSegmentBigPhi','Big_phi_M', 'phi_M', 'prob_M', 'MIP_M', 'M_IRR_M', 'MIP_M_subsys');
            %fprintf('this_subset=%s: Big_phi=%f\n',mod_mat2str(subsets{sub_index}),Big_phi_M(sub_index));
        end   
    end
end

% Save removal network if we computed it
if op_extNodes == 1 
    network.removal_networks = removal_networks;
end
%% display
% Verbose output?
if op_console
    fprintf('\n')
    fprintf('--------------------------------------------------------------\n\n')
    fprintf('Big phi values in subset this_subset:\n\n')
    for sub_index = 1: network.num_states-1
        if (Big_phi_M(sub_index) ~= 0 && ~isnan(Big_phi_M(sub_index)))
            fprintf('this_subset=%s: Big_phi=%f\n',mod_mat2str(subsets{sub_index}),Big_phi_M(sub_index));
        end
    end
end
end

function PotIrrComplex = checkStrongCon(this_subset, network)
    if length(this_subset) == 1
        % Check for self loop
        PotIrrComplex = network.connect_mat(this_subset, this_subset);
    else    
        J_sparse = sparse(network.connect_mat(this_subset, this_subset));
        [X,PotComplex] = graphconncomp(J_sparse);
        PotIrrComplex = length(unique(PotComplex))==1;
    end
end

function MIP_M_subsys = MIP_subsys_nodes(MIP,this_subset)
    MIP_M_subsys = cell(MIP);
    for i = 1:size(MIP,1)
        temp = reshape(MIP{i},[],8);
        for j = 1:length(temp)
            temp{j} = this_subset(temp{j});
        end    
        MIP_M_subsys{i} = reshape(temp,[2 2 2]);
    end    
end