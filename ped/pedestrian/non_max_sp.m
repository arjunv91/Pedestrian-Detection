function [drect,dscores]=non_max_sp(rect,scores,param) 
    indx = find(scores > param.th);
    if(size(indx) <=1)
        drect=rect(indx,:);
        dscores=scores(indx);
        return;
    end

    dthresh = 1e-2;
    minw = min(rect(indx,3));
    minh = min(rect(indx,4));
    
    %scale this to the size of the smallest
    param.sw = param.sw*minw;
    param.sh = param.sh*minh;
    
    p = [rect(indx,1)+0.5*rect(indx,3) rect(indx,2)+0.5*rect(indx,4) log(rect(indx,3)/minw) log(rect(indx,4)/minh)];
    w = scores(indx) - param.th;
    pmode = zeros(size(p));
    wmode = zeros(size(w));
    for i = 1:size(p,1)
        [pmode(i,:) wmode(i,:)] = compute_mode(i,p,w,param);
    end
    [umode,uscore] = compute_unique_modes(pmode,wmode,dthresh,param);
    %convert to rectangles again
    sw = exp(umode(:,3))*minw;
    sh = exp(umode(:,4))*minh;
    drect = [umode(:,1)-0.5*sw umode(:,2)-0.5*sh sw sh];
    dscores = uscore + param.th;
end
%% compute modes
function [pmode,wmode]=compute_mode(i,p,w,param)
    pmode = p(i,:);
    wmode = w(i);
    npts = size(p,1);
    tallones = ones(npts,1);
    vars = [param.sw*exp(p(:,3)) param.sh*exp(p(:,4)) param.ss*tallones param.ss*tallones];
    vars = vars.^2;
    
    while(1)
        d = p - repmat(pmode,[npts 1]);
        d = d.^2;
        wd = w.*exp(-sum(d./vars,2));
        wd = wd/sum(wd);
        pmode_new = wd'*p;
        if(mean(abs(pmode_new-pmode)) < 1e-3)
            break;
        end
        pmode = pmode_new;
    end
    wmode = sum(w.*wd);
end
%% compute the unique modes
function [umode, uscore]=compute_unique_modes(pmode,wmode,thresh,param)
    npts = size(pmode,1);		
    tallones = ones(npts,1);
    all=1:npts;
    uniq=[];
    
    while(~isempty(all))
        i=all(1);
        uniq = [uniq i];
        d = pmode(all,:) - repmat(pmode(i,:),size(all,2),1);
        d = mean(abs(d),2);
        samei=d<thresh;
        all(samei) = [];
    end
    umode = pmode(uniq,:);
    uscore = wmode(uniq,:);
end