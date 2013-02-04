function [Big_phi_M phi_M prob_M subsets MIP_M M_IRR_M network] = big_phi_all(network,whole_sys_state)
% compute Big-phi in every possible subset
op_console = network.options(8);
op_parfor = network.options(9); % used by Animat program
op_strongconn = network.options(10);
op_removal = network.options(11);

N = network.num_nodes; % number of elements in the whole system
nodes_vec = network.full_system;

% subset - build a cell array that contains all of the subsets
% subsets builds arrays that use the actual node numbers as opposed to
% logicals - perhaps we should make one of these that is global as well
subsets = cell(network.num_states-1,1); % subtract one since we don't consider the empty system
for i = 1:network.num_states-1 % don't include empty set, this is why for-loop starts at 2
    subsets{i} = nodes_vec(logical(network.b_table{i+1,N}));
end

% compute big phi in every possible subset
Big_phi_M = zeros(network.num_states-1,1); % Big_phi for each subset except the empty set
phi_M = cell(network.num_states-1,1);
prob_M = cell(network.num_states-1,2); 
MIP_M = cell(network.num_states-1,1); % the partition that gives Big_phi_MIP for each subset
M_IRR_M = cell(network.num_states-1,1);
if op_removal == 0
    removal_network = cell(network.num_states-1,1);
end
% With parfor it's probably faster for a single simulation, if many simulations are run in parallel,
% then it's better to do the for loop which enables the back-passing of network, so BR and FR don't 
% have to be calculated in each loop and the Complex Search can later access
% all the distributions in BRs and FRs
if op_parfor == 1
    parfor sub_index = 1:network.num_states-1 % for all non empty subsets of the system\     
        this_subset = subsets{sub_index}; % get the subset
        if op_strongconn == 0
            PotIrrComplex = checkStrongCon(this_subset, network);
        else 
            PotIrrComplex = 1;
        end    
        if PotIrrComplex == 1
            if op_removal == 0
                %Put an extra thing into network with the new connectivity
                %matrices and the new nodes for each subset
                %Actually it's better to but that into big_phi_all and only
                %do it for the potential complexes...
                removal_network{sub_index} = cpt_removal_network(this_subset,network);
            end  
            [Big_phi phi prob_cell MIP M_IRR] = big_phi_comp_fb(this_subset,whole_sys_state,network); 

            MIP_M{sub_index} = MIP;
            Big_phi_M(sub_index) = Big_phi; % Big_phi for each subset
            phi_M{sub_index} = phi; % Set of small_phis for each purview of each subset
            M_IRR_M{sub_index} = M_IRR; % numerators of purviews with non-zero/positive phi
            % concept distributions
            prob_M(sub_index,:) = prob_cell(:); % first layer is subset, second is purview, third is backward/forward
        end  
    end
else
    for sub_index = 1:network.num_states-1 % for all non empty subsets of the system\
        this_subset = subsets{sub_index}; % get the subset
        if op_strongconn == 0
            PotIrrComplex = checkStrongCon(this_subset, network);
        else 
            PotIrrComplex = 1;
        end  
        if PotIrrComplex == 1

            [Big_phi phi prob_cell MIP M_IRR network] = big_phi_comp_fb(this_subset,whole_sys_state,network); 

            MIP_M{sub_index} = MIP;
            Big_phi_M(sub_index) = Big_phi; % Big_phi for each subset
            phi_M{sub_index} = phi; % Set of small_phis for each purview of each subset
            M_IRR_M{sub_index} = M_IRR; % numerators of purviews with non-zero/positive phi
            % concept distributions
            prob_M(sub_index,:) = prob_cell(:); % first layer is subset, second is purview, third is backward/forward  
        end   
    end
end

if op_removal == 0 && op_parfor == 1
    network.removal_networks = removal_networks;
end
%% display
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
        PotIrrComplex = network.connect_mat(this_subset, this_subset);  %Check for self loop
    else    
        J_sparse = sparse(network.connect_mat(this_subset, this_subset));
        [X,PotComplex] = graphconncomp(J_sparse);
        PotIrrComplex = length(unique(PotComplex))==1;
    end
end
