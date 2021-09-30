# -*- coding: utf-8 -*-
# import matplotlib.pyplot as plt

import numpy as np
import random
import collections
import typing

import torch

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

from Common import PARTIES
from EvaluatePlayer import EvaluatePlayerCurrent

"""# вычисление результата популяции

## классы
"""


class IEvaluatePopulation():
    def evaluate(self, population, train):
        pass


class EvaluatePopulationCheck(IEvaluatePopulation):
    def evaluate(self, population, train):
        super().evaluate(population, train)
        assert (population is not None)


class EvaluatePopulationBase(EvaluatePopulationCheck):
    def __init__(self, num_parties=PARTIES['random']):
        super().__init__()

        self.num_parties = num_parties
        self.evaluate_player = EvaluatePlayerCurrent(num_parties=num_parties)

    def evaluate(self, population, train):
        super().evaluate(population, train)

        [self.evaluate_player.evaluate(player, train) for player in population.players]

        return population


class EvaluatePopulationCurrent(EvaluatePopulationBase):
    __version = 1



