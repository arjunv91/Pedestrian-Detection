%computes the locations of the grid points
function [ww hh] = get_sampling_grid(w,h,blocks)
   num_levels = size(blocks,2);
   ww = cell(num_levels,1);
   hh = cell(num_levels,1);
   for level=1:num_levels
     bw = blocks(1,level);
     bh = blocks(2,level);
     offsetw = floor(mod(w,bw)/2);
     offseth = floor(mod(h,bh)/2);
     [ww{level},hh{level}]=meshgrid(offsetw:bw:w,offseth:bh:h);
   end
end