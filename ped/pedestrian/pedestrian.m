function [feat_time] = pedestrian(image)
%% non max supression
nmax_param.sw = 0.1;
nmax_param.sh = 0.1;
nmax_param.ss = 1.3;
nmax_param.th = 0.0;

%% detector is run at this scaleratio with a stride of 8x8
scaleratio = 2^(1/8);

%% load precomputed models
load approx_models;
approx_model_hard = approx_models{2}; 

%% add path to fast iksvm prediction code
addpath ../libsvm/

%% run the detector 
feat_time = run_detector(image,approx_model_hard,scaleratio,nmax_param);
end
