
function [] = check_masks(filename)

   fid_r = fopen(filename, 'r');

   while ~feof(fid_r)
       
       folder = fgetl(fid_r);
   
       sat = imread(strcat(folder, '/sat.png'));
       
       debug_mask(sat, strcat(folder, '/mask_road.png'));
       debug_mask(sat, strcat(folder, '/mask_disconn.png'));
       debug_mask(sat, strcat(folder, '/mask_other.png'));
    
   end
   
end

function [status] = wait()

   k = 0;
    
   while (k ~= 1)
       
       k = waitforbuttonpress;
       key = get(gcf,'currentcharacter'); 
       
       switch key
          case 116 % 116 is lowercase t
              status = 1;
          case 13 % 13 is the return key 
              status = 0;
          otherwise % Wait for a different command.
       end
      
   end
   
end

function [blended_img] = blend_img(img, mask, alpha)
    sz = size(mask);
    red_mask = zeros(sz);
    red_mask(mask) = 255;
    green_mask = zeros(sz);
    blue_mask = zeros(sz);
    color_mask = uint8(cat(3, red_mask(:,:,1), green_mask(:,:,1), blue_mask(:,:,1)));
    blended_img = alpha * img + (1- alpha) * color_mask;
end

function [] = debug_mask(sat, mask_path)

    result = 1;

    if exist(mask_path)
           
       mask = logical(imread(mask_path));
       try
           imshow(blend_img(sat, mask, 0.6));
           result = wait();
       catch ME
           fprintf(1, 'ERROR --> %s\n',mask_path);
           fprintf(1,'%s\n',ME.identifier);
           fprintf(1,'%s\n',ME.message);
       end
       
    else
        fprintf(1, 'NO EXISTE --> %s\n',mask_path);
        result = wait();
    end
    
    if result == 1
        while result
            fprintf(1, 'ARREGLANDO --> %s\n',mask_path);
            result = wait();
            if result == 1
                try 
                    mask = logical(imread(mask_path));
                    imshow(blend_img(sat, mask, 0.6));
                catch ME
                    fprintf(1,'%s\n',ME.identifier);
                    fprintf(1,'%s\n',ME.message);
                end    
            end
        end
    end
    
end

