function [feature_time] = run_detector(image,approx_model_hard,scaleratio,nmax_param)

%non changable parameters
nori=9; % number of bins
border=2;
block_sizes = [ 64 32 16 6;  % block height, width in each column
                64 32 16 6];
full_360=0; window_size=[128 64]; 

%compute features on an image

fprintf(1,'[computing features over scalespace]\n');
feature_time = 0;
classification_time = 0;

stridew = 16;
strideh = 16; 
nlevels =size(block_sizes,2);

offh=0; offw=0;
tic;
[feats,nwin_posw1,nwin_posh1,nwinw1,nwinh1] =  compute_features(image,nori,full_360,border,window_size,block_sizes,nlevels,strideh,stridew,scaleratio,offh,offw);
feature_time = feature_time + toc;

tic;
labels=ones(size(feats,1),1);
e1 = fiksvm_predict(labels,feats,approx_model_hard,'-e 0 -a 1'); 
classification_time = classification_time + toc;

offh=8; offw=0;
[feats,nwin_posw2,nwin_posh2,nwinw2,nwinh2] =  compute_features(image,nori,full_360,border,window_size,block_sizes,nlevels,strideh,stridew,scaleratio,offh,offw);
feature_time = feature_time + toc;

tic;
labels=ones(size(feats,1),1);
e2 = fiksvm_predict(labels,feats,approx_model_hard,'-e 0 -a 1'); 
classification_time = classification_time + toc;

offh=0; offw=8;
[feats,nwin_posw3,nwin_posh3,nwinw3,nwinh3] =  compute_features(image,nori,full_360,border,window_size,block_sizes,nlevels,strideh,stridew,scaleratio,offh,offw);
feature_time = feature_time + toc;

tic;
labels=ones(size(feats,1),1);
e3 = fiksvm_predict(labels,feats,approx_model_hard,'-e 0 -a 1'); 
classification_time = classification_time + toc;

offh=8; offw=8;
[feats,nwin_posw4,nwin_posh4,nwinw4,nwinh4] =  compute_features(image,nori,full_360,border,window_size,block_sizes,nlevels,strideh,stridew,scaleratio,offh,offw);
feature_time = feature_time + toc;

tic;
labels=ones(size(feats,1),1);
e4 = fiksvm_predict(labels,feats,approx_model_hard,'-e 0 -a 1'); 
classification_time = classification_time + toc;

threshold = nmax_param.th;

e = cat(1,e1,e2,e3,e4);
win_posw = cat(2,nwin_posw1,nwin_posw2,nwin_posw3,nwin_posw4);
win_posh = cat(2,nwin_posh1,nwin_posh2,nwin_posh3,nwin_posh4);
winh = cat(2,nwinh1,nwinh2,nwinh3,nwinh4);
winw = cat(2,nwinw1,nwinw2,nwinw3,nwinw4);

indx = e > nmax_param.th;
rawr = [win_posw(indx)' win_posh(indx)' winw(indx)' winh(indx)'];
raws = e(indx);

[dr,ds] = non_max_sp(rawr,raws,nmax_param);
fprintf('%.2fs to compute features, %.2fs to classify %i features..\n',feature_time, classification_time, length(e));
%draw the final detections 
draw_det(image, dr(:,1),dr(:,2),dr(:,3),dr(:,4),ds,threshold);
title(sprintf('Pedestrian Detections [threshold = %.2f]',threshold));
end
