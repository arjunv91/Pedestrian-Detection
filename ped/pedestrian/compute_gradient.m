% takes an rgb image and returns the gradient image
function R=compute_gradient(I,nori)
    I=rgb2gray(I);
    nbins=nori;

    % make the derivative filters
    paper_x = [ 0 0 0; 1 0 -1; 0 0 0]/2;
    paper_y = paper_x';

    % apply the derivative filters
    sx = conv2(I,flipud(fliplr(paper_x)),'same');
    sy = conv2(I,flipud(fliplr(paper_y)),'same');
    [X,Y]=meshgrid([1:size(sx,2)],[1:size(sx,1)]);
    a = atan(sy./(sx+1e-15));
    m = ((sx.^2)+(sy.^2)).^0.5;  % edge magnitude

    R = zeros(size(I,1), size(I,2), nori);

    % make bins and compute histogram
    min_bin = -pi/2;
    max_bin = pi/2;
    bin_size = (max_bin-min_bin)/nbins;
    center_offset = bin_size/2;
    bin_centers = (min_bin+center_offset):bin_size:(max_bin-center_offset);
    
    %compute bin index
    bin = min(nbins,max(1,round(nbins*(a-min_bin)/(max_bin-min_bin)+0.5)));
    
    %no smoothing (performs better on test)
    R(sub2ind(size(R),Y,X,bin)) = m;
    
    % linearly interpolate the membership between adjacent bins
    %f=(a - bin_centers(bin))/bin_size;
    %nhd_bin = mod(bin + sign(f)-1,nbins)+1;
    %R(sub2ind(size(R),Y,X,bin)) = m.*(1-abs(f));
    %R(sub2ind(size(R),Y,X,nhd_bin)) = m.*abs(f);

end
%% takes an rgb image as an input and converts to grayscale(double)
function Igray=rgb2gray(Irgb)
    if(size(Irgb,3) ~= 3 )
      Igray = Irgb;
    else
      Igray=zeros(size(Irgb,1),size(Irgb,2),'double');
      Igray=0.3.*Irgb(:,:,1) + 0.59.*Irgb(:,:,2) + 0.11.*Irgb(:,:,3);
      Igray=double(Igray)/255;
    end
end
