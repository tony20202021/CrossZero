# -*- coding: utf-8 -*-
# import matplotlib.pyplot as plt

import numpy as np
import random
import collections
import typing

import torch

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

from PlayerValueBased import PlayerCurrent

"""# популяция

## классы
"""


class IPopulation():
    def __init__(self,
                 *args,
                 **kwargs,
                 ):
        super().__init__()

        self.players = None


class PopulationCheck(IPopulation):
    def __init__(self,
                 *args,
                 num_players=1,
                 player_class=PlayerCurrent,
                 **kwargs,
                 ):
        super().__init__(*args, **kwargs)

        assert (num_players > 0)
        assert (player_class is not None)


class PopulationPlayers(PopulationCheck):
    def __init__(self,
                 *args,
                 num_players=1,
                 player_class=PlayerCurrent,
                 **kwargs,
                 ):
        super().__init__(num_players=num_players, player_class=player_class)

        self.players = np.array([player_class(**kwargs) for index_player in range(num_players)])


class PopulationSort(PopulationPlayers):
    def sort_players(self):
        self.players = self.players[torch.cat([torch.Tensor([p.score['win']]) for p in self.players]).argsort(descending=True).tolist()]


class PopulationUpdate(PopulationSort):
        def update(self):
            pass


class PopulationMutate(PopulationUpdate):
    def __init__(self, num_players, player_class=PlayerCurrent, hidden_count=2):
        super().__init__(num_players, player_class, hidden_count)

        self.len_copy = int(0.1 * len(self.players))
        self.len_mutate = int(0.5 * len(self.players))
        self.len_reproduce = int(0.3 * len(self.players))
        self.len_random = int(0.1 * len(self.players))

    def generate_mutate(self,
                        index_begin_destination, index_end_destination,
                        index_begin_source, index_end_source,
                        probability=0.1, max_volume=0.1):
        index_source = index_begin_source
        for index_destination in range(index_begin_destination, index_end_destination):
            self.players[index_destination].mutate(self.players[index_source], probability, max_volume)
            index_source = (index_source + 1) % (index_end_source - index_begin_source)

    def generate_mutate_all(self,
                            index_begin_destination, index_end_destination,
                            index_begin_source, index_end_source,
                            ):
        parameters = [
            {'probability': 0.01, 'max_volume': 0.01},
            {'probability': 0.1, 'max_volume': 0.1},
            {'probability': 0.1, 'max_volume': 0.9},
            {'probability': 0.9, 'max_volume': 0.1},
            {'probability': 0.9, 'max_volume': 0.9},
        ]
        len_batch = (index_end_destination - index_begin_destination) // len(parameters)
        index_begin_destination_batch = None
        index_end_destination_batch = None
        for index, parameter in enumerate(parameters):
            if index_begin_destination_batch is None:
                index_begin_destination_batch = index_begin_destination
            else:
                index_begin_destination_batch = index_end_destination_batch
            index_end_destination_batch = min(index_end_destination, index_begin_destination_batch + len_batch)
            self.generate_mutate(index_begin_destination_batch, index_end_destination_batch,
                                 index_begin_source, index_end_source,
                                 parameter['probability'], parameter['max_volume'])

        if (index_end_destination_batch < index_end_destination):
            self.generate_mutate(index_end_destination_batch, index_end_destination,
                                 index_begin_source, index_end_source,
                                 parameters[0]['probability'], parameters[0]['max_volume'])

    def generate_reproduce(self,
                           index_begin_destination, index_end_destination,
                           index_begin_source, index_end_source,
                           probability_1=0.5):
        index_destination = index_begin_destination
        while (index_destination < index_end_destination):
            index_source_1 = np.random.randint(index_end_source - index_begin_source)
            index_source_2 = np.random.randint(index_end_source - index_begin_source)
            if (index_source_1 != index_source_2):
                self.players[index_destination].reproduce(self.players[index_source_1], self.players[index_source_2], probability_1)
                index_destination += 1

    def generate_reproduce_all(self,
                        index_begin_destination, index_end_destination,
                        index_begin_source, index_end_source):
        parameters = [
            {'probability': 0.1},
            {'probability': 0.5},
            {'probability': 0.9},
        ]
        len_batch = (index_end_destination - index_begin_destination) // len(parameters)
        index_begin_destination_batch = None
        index_end_destination_batch = None
        for index, parameter in enumerate(parameters):
            if index_begin_destination_batch is None:
                index_begin_destination_batch = index_begin_destination
            else:
                index_begin_destination_batch = index_end_destination_batch
            index_end_destination_batch = min(index_end_destination, index_begin_destination_batch + len_batch)
            self.generate_reproduce(index_begin_destination_batch, index_end_destination_batch,
                                    index_begin_source, index_end_source,
                                    parameter['probability'])

        if (index_end_destination_batch < index_end_destination):
            self.generate_reproduce(index_end_destination_batch, index_end_destination,
                                    index_begin_source, index_end_source,
                                    parameters[0]['probability'])


    def update(self):
        # 0..len_copy - ничего не меняем

        # len_mutate
        index_begin_source = 0
        index_end_source = self.len_copy
        index_begin_destination = self.len_copy
        index_end_destination = min(self.len_copy + self.len_mutate, len(self.players))
        self.generate_mutate_all(index_begin_destination, index_end_destination,
                             index_begin_source, index_end_source)

        # len_reproduce
        index_begin_source = 0
        index_end_source = self.len_copy
        index_begin_destination = self.len_copy + self.len_mutate
        index_end_destination = min(self.len_copy + self.len_mutate + self.len_reproduce, len(self.players))
        self.generate_reproduce_all(index_begin_destination, index_end_destination,
                                index_begin_source, index_end_source)

        # len_random
        # все остальное до конца
        index_source = 0
        index_begin = self.len_copy + self.len_mutate + self.len_reproduce
        index_end = len(self.players)
        for index_destination in range(index_begin, index_end):
            self.players[index_destination].random()
            index_source = (index_source + 1) % self.len_copy


class PopulationValueBased(PopulationUpdate):
    def update(self):
        for player in self.players:
            player.update()


class PopulationCurrent(PopulationValueBased):
    __version = 2

