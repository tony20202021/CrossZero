# -*- coding: utf-8 -*-

"""
вычисление результата популяции
"""

from Common import PARTIES
from EvaluatePlayer import EvaluatePlayerCurrent


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



