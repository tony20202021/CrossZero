# -*- coding: utf-8 -*-

"""
тренировка популяции
"""

from Common import PARTIES
from EvaluatePopulation import EvaluatePopulationCurrent


class ITrainPopulation():
    def __init__(self, num_parties=PARTIES['random'], evaluate_population_class=EvaluatePopulationCurrent,
                 num_epoch=1000):
        super().__init__()

    def train(self, population):
        pass


class TrainPopulationCheck(ITrainPopulation):
    def __init__(self, num_parties=PARTIES['random'], evaluate_population_class=EvaluatePopulationCurrent,
                 num_epoch=1000):
        super().__init__(num_parties, evaluate_population_class)
        assert (num_parties > 0)
        assert (evaluate_population_class is not None)
        assert (num_epoch > 0)

    def train(self, population):
        super().train(population)
        assert (population is not None)


class TrainPopulationBase(TrainPopulationCheck):
    def __init__(self, num_parties=PARTIES['random'], evaluate_population_class=EvaluatePopulationCurrent,
                 num_epoch=1000):
        super().__init__(num_parties, evaluate_population_class)

        self.num_parties = num_parties
        self.evaluate_population = evaluate_population_class(num_parties=num_parties)
        self.num_epoch = num_epoch

    def train(self, population):
        super().train(population)

        for index_epoch in range(self.num_epoch):
            print(f"epoch:{index_epoch}/{self.num_epoch}, players:{len(population.players)}, parties:{self.num_parties}")

            self.evaluate_population.evaluate(population, train=True)

            self.evaluate_population.evaluate(population, train=False)
            # print(f"evaluate={[p.score.item() for p in population.players]}")

            population.sort_players()
            top_10 = [f"win:{p.score['win']:.3f}, lose:{p.score['lose']:.3f}, draw:{p.score['draw']:.3f}, invalid:{p.score['invalid']:.3f}  ({p.get_info()})" for p in population.players[:10]]
            print(f"top 10 = {top_10}")

            population.update()
            # print(f"mutate={[p.score.item() for p in population.players]}")

        return population


class TrainPopulationCurrent(TrainPopulationBase):
    __version = 1
