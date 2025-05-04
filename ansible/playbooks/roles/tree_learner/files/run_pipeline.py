# file is copied into "{{ root_vol }}/TreeLearn/"
import sys
import pprint
import logging

# remove default handlers and add a handler streaming to stdout
logger = logging.getLogger("TreeLearn")
for handler in logger.handlers[:]:
    logger.removeHandler(handler)
logging.basicConfig()
ch = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)
logger.setLevel(logging.INFO)

# import needed modules and config
sys.path.append(f"/tools/pipeline")
from pipeline import run_treelearn_pipeline
from tree_learn.util import get_config

config_path = f"configs/pipeline/pipeline.yaml"
config = get_config(config_path)
print(pprint.pformat(config.toDict(), indent=2))


# run pipeline
logger.info('running pipeline')
run_treelearn_pipeline(config)
logger.info('pipeline finished')
