# -*- coding: utf-8 -*-

"""
модуль для запуска из PyCharm

# игра в крестики-нолики
* нейросеть
* обучение:
  * генетический алгоритм
* автоматический подбор:
  * количества нейронов в скрытом слое
  * количества скрытых слоев
"""

import pandas as pd
import numpy as np
desired_width = 620
pd.set_option('display.width', desired_width)
np.set_printoptions(linewidth=desired_width)


from Population import PopulationCurrent
from EvaluatePopulation import EvaluatePopulationCurrent
from TrainPopulation import TrainPopulationCurrent


train_population = TrainPopulationCurrent(num_parties=100, evaluate_population_class=EvaluatePopulationCurrent, num_epoch=2000)
# print(train_population)

population = PopulationCurrent(num_players=1, hidden_count=30)
# print(population)

print(train_population.train(population))


