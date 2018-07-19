import numpy as np
import skimage.io
from PIL import Image
import urllib.request
import io
from skimage import exposure
from urllib.parse import quote
import sys
import shutil
from pathlib import Path, PosixPath
import os

base_URL = "https://maps.googleapis.com/maps/api/staticmap?key=AIzaSyDvgF0JSBrlYLDzY7pPqtcBSgGslmaAlzw&zoom=19&format=png&maptype=roadmap&style=color:0x000000&style=element:labels%7Cvisibility:off&style=feature:road%7Celement:geometry%7Ccolor:0xffffff%7Cvisibility:on&style=feature:road.highway%7Celement:geometry%7Ccolor:0xffffff%7Cvisibility:on&style=feature:road.local%7Celement:geometry%7Cvisibility:off&size=640x640&scale=2"

satellite_URL = "https://maps.googleapis.com/maps/api/staticmap?maptype=satellite&zoom=19&format=png&size=640x640&scale=2&key=AIzaSyDvgF0JSBrlYLDzY7pPqtcBSgGslmaAlzw"

sys.argv.pop(0)
coord = tuple(sys.argv)

newpath = r'img/{}_{}'.format(*coord)
if os.path.exists(newpath):
    shutil.rmtree(newpath, ignore_errors=True)
os.makedirs(newpath)

symlink_path = 'new_roads/{}_{}'.format(*coord)
if not os.path.exists(symlink_path):
    os.symlink('{}/{}'.format(os.getcwd(),newpath), symlink_path)
    
new_url = base_URL + "&center=" + quote("{}, {}".format(*coord))
new_satellite_url = satellite_URL + "&center=" + quote("{}, {}".format(*coord))

with urllib.request.urlopen(new_url) as url:
	f = io.BytesIO(url.read())
img = exposure.rescale_intensity(np.array(Image.open(f)))
skimage.io.imsave(newpath + "/mask.png",img)

img_satellite = skimage.io.imread(new_satellite_url)
skimage.io.imsave(newpath + "/sat.png",img_satellite)

cmd = r'/home/david/matlab/bin/matlab -nosplash -nodesktop -r "road_segmentation {}; quit"'.format(newpath)
os.system(cmd)

p = Path(newpath)
for sec_img in p.glob('*/*/*.png'):
    if sec_img.parts[-1] in ['sat_eq.png']:
        symlink_path_img = 'img_tmp/{}'.format(':'.join(sec_img.parts))
        if not os.path.exists(symlink_path_img):
            os.symlink(os.getcwd() + '/' + '/'.join(sec_img.parts), symlink_path_img)
        

            
