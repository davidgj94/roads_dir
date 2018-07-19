import shutil
from pathlib import Path, PosixPath
import os
import itertools

def clean_subsections(subsections):
    
    for subsec in subsections:
        
        mask_short = list(subsec.glob("mask_short.png"))
        mask_disconn = list(subsec.glob("mask_disconn.png"))
        mask_other = list(subsec.glob("mask_other.png"))
        
        if not (mask_short or mask_disconn or mask_other):
            for img in subsec.glob("*.png"):
                os.remove('/'.join(img.parts))
            subsec.rmdir()

def get_subdirs(p):
    return [x for x in p.iterdir() if x.is_dir()]


for road in get_subdirs(Path('new_roads')):
    
    sections = get_subdirs(road)
    
    for section in sections:
        
        sec_skel = list(section.glob("sec_skel.png"))
        if sec_skel:
            os.remove('/'.join(sec_skel[0].parts))
        
        subsections = get_subdirs(section)
            
        clean_subsections(subsections)
        
        if not list(section.glob("*")):
            section.rmdir()
            
            
    if not get_subdirs(road):
        print(road)
        os.remove('/'.join(road.parts))
        

    

