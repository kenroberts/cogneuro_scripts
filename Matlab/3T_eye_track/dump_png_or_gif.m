function dump_png_or_gif(filename)
% makes a 256 color png or gif out of the current figure.
%
% DUMP_PNG_OR_GIF(filename)
%
% chooses PNG or GIF based on extension.
%
    num_colors = 256;
    [my_im, my_map] = rgb2ind(frame2im(getframe(gcf)), num_colors);
    imwrite(my_im, my_map, filename);
return;
