import shutil
from pathlib import Path, PosixPath
import os
import sys
import pdb

def get_names_set(png_glob):
    return set(map(lambda x: x.parts[-1], png_glob))


labels_dir = sys.argv[1]
p = Path('img_tmp')
   
sat_set = get_names_set(p.glob('*.png'))
short_set = get_names_set(p.glob('mask_short/*.png'))
disconn_set = get_names_set(p.glob('mask_disconn/*.png'))
other_set = get_names_set(p.glob('mask_other/*.png'))
arrow_set = get_names_set(p.glob('mask_arrow/*.png'))

total_set = short_set | disconn_set | other_set | arrow_set
diff_set = sat_set - total_set
#pdb.set_trace()

if diff_set:
    print 'Faltan roads!!'
    sys.exit()

for mask in p.glob('*/*.png'):
    img_name = os.path.splitext(mask.parts[-1])[0]
    dest_path =  labels_dir + '{}/{}.png'.format(img_name, mask.parts[-2].split('_')[1])
    src_path = '/'.join(mask.parts)
    shutil.copy(src_path,dest_path)

    
