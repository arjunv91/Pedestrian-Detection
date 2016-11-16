%compute features over scalespace
function [feats,win_posw,win_posh,winw,winh] = compute_features(im,nori,full_360,border,window_size,block_sizes,nlevels,strideh,stridew,scaleratio,offh,offw,model)
  
  if (exist('model')==1),
    fprintf('Using model\n');  % will return evaluation of model at
                               % each locaiton instead of features
  end
  if (isnumeric(im)),
    II = im;
  else
    II = imread(im);
  end
  if (size(II,3) > 1), II=rgb2gray(II);end;

  III = imresize(II,[256 320]);
  II = im2double(III);  
    
  IW = window_size(2);
  IH = window_size(1);
  blocks = block_sizes;

  
  
  [h w nch] = size(II);
  [gw,gh] = get_sampling_grid(IW,IH,blocks);

 
  num_scales=min(floor(log(h/IH)/log(scaleratio)),floor(log(w/IW)/log(scaleratio)))+1;
  scales = scaleratio.^(0:num_scales-1);
  
  num_feats = 0;

  %padding images 
  padw = 8; padh = 8;

  fake_stridew = 8;
  fake_strideh = 8;

  tdesc= 0;
    for s = 1:num_scales
%      I = imresize(II,1/scales(s));
%      I = padarray(I,[padh padw],'replicate');
      
      %generate a bunch of locations
      h = ceil((size(II,1)/scales(s)))+2*padh;
      w = ceil((size(II,2)/scales(s)))+2*padw; 
      offsetw = offw+max(border,floor(mod(w,fake_stridew)/2))+1;
      offseth = offh+max(border,floor(mod(h,fake_strideh)/2))+1;
      [loch,locw] = meshgrid(offseth:strideh:h-IH-border+1,offsetw:stridew:w-IW-border+1);
      tdesc =tdesc+length(loch(:));
    end
  
    td = 0; for ii=1:length(gw), td=td+(size(gw{ii},1)-1)*(size(gw{ii},2)-1); end
    fdim = td*nori;
    
    feats = zeros(tdesc,fdim,'single');    
  
  
  for s = 1:num_scales
    I = imresize(II,1/scales(s));
    I = padarray(I,[padh padw],'replicate');

    %generate a bunch of locations
    [h w nch] = size(I);
    offsetw = offw+max(border,floor(mod(w,fake_stridew)/2))+1;
    offseth = offh+max(border,floor(mod(h,fake_strideh)/2))+1;
    [loch,locw] = meshgrid(offseth:strideh:size(I,1)-IH-border+1,offsetw:stridew:size(I,2)-IW-border+1);

    R = compute_gradient(I,nori);
    R(1:border,:,:)=0;
    R(:,1:border,:)=0;
    R(end-border+1:end,:,:)=0;
    R(:,end-border+1:end,:)=0;
%    keyboard
    
    nr = sum(R,3);
    if (mod(strideh,8)~=0)||(mod(stridew,8)~=0),
      fprintf('XXXXXXXX  THIS VERSION NEEDS mod(stride{h,w},16)==0 XXXXXXXX\n');
    end

    mi = offseth;
    mj = offsetw;
    nr = nr(mi:end,mj:end);
    
    [ai,aj]=size(nr);
    padi = 16-mod(ai,16); %% assumes 16x16 normalization
    padj = 16-mod(aj,16);
    nr = [nr, zeros(size(nr,1),padj); zeros(padi,size(nr,2)),zeros(padi,padj)];
    nr = conv2(nr,ones(16,1),'same');
    nr = conv2(nr,ones(1,16),'same');
    nr = nr(8:16:end,8:16:end);
    nr = imresize(nr,16,'nearest');
    nr = nr(1:end-padi,1:end-padj);
    nr = nr + 4;  % value depends on many things...
%    nr = repmat(nr,[1 1 size(R,3)]);
    newR = zeros(size(R),'single');
    for chind=1:size(R,3),
      newR(mi:end,mj:end,chind)=R(mi:end,mj:end,chind)./nr;
    end
    
    
    td = 0; for ii=1:length(gw), td=td+(size(gw{ii},1)-1)*(size(gw{ii},2)-1); end
    
    my_bounds = zeros(td,5); count = 0;
    level_weights = (2.^(0:length(gw)-1));
    for ii=1:length(gw),
      for jj=2:size(gw{ii},2),
        for kk=2:size(gw{ii},1),
          count = count + 1;
          my_bounds(count,:) = [gh{ii}(kk-1,jj-1) gh{ii}(kk,jj) gw{ii}(kk-1,jj-1) gw{ii}(kk,jj) level_weights(ii)];
        end
      end
    end
    
    f = mex_feature(single(newR),int32([loch(:),locw(:)]),int32(my_bounds));

    ii = [1:252];
    ii = repmat(ii,[1,9]);
    [sv,so]=sort(ii);
    f=f(:,so);
    
    for i=1:size(f,1),
      f(i,:) = f(i,:)/sum(f(i,1:18)+1e-8);
    end
    
    
    %correct for padding
    locw(:) = locw(:) - padw;
    loch(:) = loch(:) - padh;

    %concatenate the features
    count = size(f,1);
    feats(num_feats+1:num_feats+count,:)  = f;
    win_posw(num_feats+1:num_feats+count) = round(locw(:)*scales(s)); 
    win_posh(num_feats+1:num_feats+count) = round(loch(:)*scales(s)); 
    winw(num_feats+1:num_feats+count) = round(IW*scales(s)); 
    winh(num_feats+1:num_feats+count) = round(IH*scales(s)); 
    fprintf(1,'\tscale=%.3f [%dx%d], feats=%d\n',scales(s),round(IW*scales(s)),round(IH*scales(s)),count);
    num_feats = num_feats + count;
  
  end
  
  if (num_feats<tdesc),
    fprintf('trimming extra feats\n');
    feats = feats(1:num_feats,:);
  elseif (num_feats>tdesc)
    fprintf('umm  more feats than expected\n');
    keyboard
  end