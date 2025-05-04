import sys 

root_dir = '/mnt/tlvol/'
tldir = f'{root_dir}/TreeLearn'

sys.path.append(f"{tldir}/tools/pipeline")
from pipeline import run_treelearn_pipeline
import argparse, pprint
from tree_learn.util import get_config

config_path = f"{tldir}/configs/pipeline/pipeline.yaml"
config = get_config(config_path)

# adjust config
config.forest_path = f"{root_dir}/pipeline/forests/collective.npy"
config.dataset_test.data_root = f"{root_dir}/pipeline/tiles"
config.tile_generation = True
config.pretrain = f"{root_dir}/checkpoints/model_weights.pth"
config.sample_generation.stride = 0.9 # small overlap of tiles
config.shape_cfg.outer_remove = False # default value = 13.5
config.save_cfg.save_treewise = True
config.save_cfg.return_type = "voxelized_and_filtered"
print(pprint.pformat(config.toDict(), indent=2))


import logging
logger = logging.getLogger("TreeLearn")
for handler in logger.handlers[:]:
    logger.removeHandler(handler)
logging.basicConfig()
ch = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)
logger.setLevel(logging.INFO)

logger.info('running pipeline')
run_treelearn_pipeline(config)
logger.info('running pipeline')

# import sys
# from importlib import reload
# import logging

# sys.path.append("/content/TreeLearn/tools/pipeline")
# import tree_learn 
# import pipeline
# import argparse, pprint

# logger = logging.getLogger("TreeLearn")
# for handler in logger.handlers[:]:
#     logger.removeHandler(handler)
# logging.basicConfig()
# ch = logging.StreamHandler(sys.stdout)
# formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
# ch.setFormatter(formatter)
# logger.addHandler(ch)
# logger.setLevel(logging.INFO)


# config_path = 'configs/pipeline/pipeline.yaml'  
# config = tree_learn.util.get_config(config_path)
# # for key, value in config.items():
# #     print(key, value)
# config.save_cfg.results_dir = 'skio/results'
# config.dataset_test.data_root = 'data/skio'
# .prep_config_tiles(config,config_path,start_at='tiles')
