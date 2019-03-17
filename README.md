# Catalyst.RL: A Distributed Framework for Reproducible RL Research

[Paper](https://arxiv.org/abs/1903.00027) & [Framework](https://github.com/catalyst-team/catalyst)

## Preparation

#### System requirements
```bash
sudo apt install -y redis
sudo apt install -y python3-dev zlib1g-dev libjpeg-dev \ 
    cmake swig python-pyglet python3-opengl libboost-all-dev \
    libsdl2-dev libosmesa6-dev patchelf ffmpeg xvfb
```

#### Python env setup
```bash
conda create -n rl python=3.6 anaconda
source activate rl
conda remove nb_conda_kernels -y
conda install -c conda-forge nb_conda_kernels -y
conda install notebook jupyter nb_conda -y
conda remove nbpresent -y
```

#### Python requirements
```bash
pip install gym['all']
pip install -r ./requirements.txt
```


## Examples

#### Local run - LunarLander

```bash
# terminal 1 - db node
redis-server --port 12000

# terminal 2 and 3
export GPUS=""  # like GPUS="0" or GPUS="0,1" for multi-gpu training
export CONFIG=./gym_lunarlander/sac_d3pg.yml  # or "td3_qd4pg.yml", "qd4pg.yml" 

# terminal 2 - trainer node
CUDA_VISIBLE_DEVICES="$GPUS" catalyst-rl run-trainer --config="${CONFIG}"

# terminal 3 - samplers node
CUDA_VISIBLE_DEVICES="" catalyst-rl run-samplers --config="${CONFIG}"

# terminal 4 - progress visualization
CUDA_VISIBLE_DEVICE="" tensorboard --logdir=./logs
```


#### Benchmark - BipedalWalker

```bash
export GPUS=""  # like GPUS="0" or GPUS="0,1" for multi-gpu training
export EXP_DIR="gym_bipedalwalker_simple"  # or "gym_bipedalwalker_hardcore"
export CONFIG=./_base/_all.yml,./_base/_agents101.yml,./_base/_qd4pg.yml,./"${EXP_DIR}"/qd4pg.yml,./_base/_ddpg.yml
export LOGDIR=./logs/"${EXP_DIR}"/ddpg-qd4pg

CUDA_VISIBLE_DEVICES="$GPUS" ./bin/grid_run.sh \
    --redis-port 12100 \
    --config "$CONFIG" \
    --logdir "$LOGDIR" \
    --param-name "shared/n_step" \
    --param-values "1, 5" \
    --param-type "int" \
    --wait-time 10800 \  # 3 hours, use 43200 for 12 hours experiment 
    --n-trials 1  # number of trials per experiment  
```


## Citation
Please cite the following paper if you feel this repository useful.
```
@article{catalyst_rl,
  title={Catalyst.RL: A Distributed Framework for Reproducible RL Research},
  author = {Kolesnikov, Sergey and Hrinchuk, Oleksii},
  journal={arXiv preprint arXiv:1903.00027},
  year={2019}
}
```

## Related Projects

- [NeurIPS 2018: AI for Prosthetics Challenge](https://github.com/Scitator/neurips-18-prosthetics-challenge): our 3rd place solution for NeurIPS competition based on [Catalyst.RL](https://github.com/catalyst-team/catalyst) 

## Contact
For any question, please contact
```bash
Sergey Kolesnikov: scitator@gmail.com
Oleksii Hrinchuk: oleksii.hrinchuk@gmail.com
```