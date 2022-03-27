# -*- coding: utf-8 -*-
"""

модуль для запуска из Colab

# игра в крестики-нолики
* нейросеть
* обучение:
  * генетический алгоритм
* автоматический подбор:
  * количества нейронов в скрытом слое
  * количества скрытых слоев
"""

# from google.colab import drive
# drive.mount('/content/drive')
#
# import sys
# sys.path.append('/content/drive/MyDrive/CrossZero')

# torch/numpy
random_seed_fix = True

"""# импорт"""

# !pip install -q pytorch-lightning

# опция -q позволяет значительно уменьшить вывод при установке пакета



import matplotlib.pyplot as plt

import numpy as np
import random
import os
import collections

import tqdm

import torch
print(torch.__version__)

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print(device)

"""### фиксируем генераторы случайных чисел"""

if random_seed_fix:
  
  seed = 12345

  random.seed(seed)
  np.random.seed(seed)

  torch.random.manual_seed(seed)

  torch.cuda.manual_seed(seed)
  torch.cuda.manual_seed_all(seed)

  torch.cuda.deterministic = True
  torch.cuda.benchmark = False

max_threads = 32

os.environ["OMP_NUM_THREADS"] = str(max_threads)
os.environ["OPENBLAS_NUM_THREADS"] = str(max_threads)
os.environ["MKL_NUM_THREADS"] = str(max_threads)
os.environ["VECLIB_MAXIMUM_THREADS"] = str(max_threads)
os.environ["NUMEXPR_NUM_THREADS"] = str(max_threads)



"""# тренировка"""

from Population import PopulationCurrent
from EvaluatePopulation import EvaluatePopulationCurrent
from TrainPopulation import TrainPopulationCurrent


train_population = TrainPopulationCurrent(num_parties=100, evaluate_population_class=EvaluatePopulationCurrent, num_epoch=2000)
# print(train_population)

population = PopulationCurrent(num_players=1, hidden_count=30)
# print(population)

print(train_population.train(population))

