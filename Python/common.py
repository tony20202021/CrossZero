# -*- coding: utf-8 -*-
# import matplotlib.pyplot as plt

import numpy as np
import random
import collections

import torch

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")


"""# глобальные константы"""

# Net
X_LEN = 3
Y_LEN = 3

# figures
FIGURES = {
  '_X_': '_X_',
  '_0_': '_0_',
  '___': '___',
}
FIGURES_TO_VALUES = {
  '_X_': 1,
  '_0_': -1,
  '___': 0,
}
VALUES_TO_FIGURES = {
  1: '_X_',
  -1: '_0_',
  0: '___',
}

# scores
SCORES_WEIGHTS = {
    'valid_move': torch.Tensor([1]).to(device).type(torch.float),
    # 'win': torch.Tensor([10]).to(device).type(torch.float),
    'win': torch.Tensor([0]).to(device).type(torch.float),
}

# parties
PARTIES = {
    'random': 10,
}

MAX_MOVES = 5

SCORE_DIGITS = 2

# templates
TEMPLATES_WIN = torch.Tensor([
    [[1, 1, 1],
     [0, 0, 0],
     [0, 0, 0]],
    [[0, 0, 0],
     [1, 1, 1],
     [0, 0, 0]],
    [[0, 0, 0],
     [1, 1, 1],
     [0, 0, 0]],
    [[1, 1, 1],
     [0, 0, 0],
     [0, 0, 0]],
    [[1, 0, 0],
     [1, 0, 0],
     [1, 0, 0]],
    [[0, 1, 0],
     [0, 1, 0],
     [0, 1, 0]],
    [[0, 0, 1],
     [0, 0, 1],
     [0, 0, 1]],
    [[1, 0, 0],
     [0, 1, 0],
     [0, 0, 1]],
    [[0, 0, 1],
     [0, 1, 0],
     [1, 0, 0]],
]).to(device).type(torch.float)
TEMPLATES_WIN = TEMPLATES_WIN.contiguous().view(TEMPLATES_WIN.shape[0], -1)


# сеть
# вход: тензор 1*9, значения (-1, 0, 1), float
# скрытые слои:
# количество слоев - пока 1, попробовать динамическое добавление
# количество нейронов - начинаем с 2, динамическое добавление
# выход: тензор 1*9, float, вероятности хода в соответствующую ячейку
class Net(torch.nn.Module):
    def __init__(self,
                 *args,
                 y_len=Y_LEN,
                 x_len=X_LEN,
                 hidden_count=1,
                 verbose=False,
                 **kwargs,
                 ):
        super().__init__(**kwargs)

        self.verbose = verbose
        self.y_len = y_len
        self.x_len = x_len
        self.input_count = y_len * x_len
        self.hidden_count = hidden_count
        self.output_count = y_len * x_len

        if self.verbose: print(f"Net: args={args}, kwargs={kwargs}")

        self.hidden = {
            'linear': torch.nn.Linear(self.input_count, self.hidden_count),
            'activation': torch.nn.ReLU(),
        }
        self.hidden['linear'].weight.requires_grad = False
        self.hidden['linear'].bias.requires_grad = False

        self.add_module('hidden:linear', self.hidden['linear'])
        self.add_module('hidden:activation', self.hidden['activation'])

        self.output = {
            'linear': torch.nn.Linear(self.hidden_count, self.output_count),
            'activation': torch.nn.Sigmoid(),
        }
        self.output['linear'].weight.requires_grad = False
        self.output['linear'].bias.requires_grad = False

        self.add_module('output:linear', self.output['linear'])
        self.add_module('output:activation', self.output['activation'])

        self.to(device)

    def forward(self, input):
        # assert(list(input.shape) == [self.y_len * self.x_len])

        result = input

        result = self.hidden['linear'](result)
        if self.verbose: print(f"hidden.linear={result}")

        result = self.hidden['activation'](result)
        if self.verbose: print(f"hidden.activation={result}")

        result = self.output['linear'](result)
        if self.verbose: print(f"output.linear={result}")

        result = self.output['activation'](result)
        if self.verbose: print(f"output.activation={result}")

        return result


class NetCheck(Net):
    def __init__(self,
                 *args,
                 use_check=False,
                 **kwargs,
                 ):
        super().__init__(**kwargs)

        if self.verbose: print(f"NetCheck: args={args}, kwargs={kwargs}")

        self.use_check = use_check

        if self.use_check:
            self.check = {
                'model': torch.nn.Sequential(collections.OrderedDict([
                    ('hidden_linear', torch.nn.Linear(self.input_count, self.hidden_count)),
                    ('hidden_activation', type(self.hidden['activation'])()),
                    ('output_linear', torch.nn.Linear(self.hidden_count, self.output_count)),
                    ('output_activation', type(self.output['activation'])()),
                ]))
            }
            # TODO: перезаписать веса

    def forward(self, input):
        result = super().forward(input)

        if self.use_check:
            check = self.check['model'](result)
            if self.verbose: print(f"check={check}")

            if self.verbose: print(f"result={result}, check={check}")
            assert ((result == check).all())

        return result


class NetMutate(NetCheck):
    def __init__(self,
                 *args,
                 **kwargs,
                 ):
        super().__init__(**kwargs)

        if self.verbose: print(f"NetMutate: args={args}, kwargs={kwargs}")

    def _mutate_parameter(self, parameter, probability=0.1, max_volume=0.1):
        mask = torch.bernoulli(torch.full(parameter.shape, probability)).int()
        volume = max_volume * max(0.000001, min(1, parameter.abs().max()))
        return torch.nn.parameter.Parameter(parameter + mask * volume * (torch.rand(parameter.shape).to(device) - 0.5))

    def mutate(self, net, probability=0.1, max_volume=0.1):
        self.hidden['linear'].weight = self._mutate_parameter(net.hidden['linear'].weight, probability, max_volume)
        self.hidden['linear'].bias = self._mutate_parameter(net.hidden['linear'].bias, probability, max_volume)
        self.output['linear'].weight = self._mutate_parameter(net.output['linear'].weight, probability, max_volume)
        self.output['linear'].bias = self._mutate_parameter(net.output['linear'].bias, probability, max_volume)

    def _reproduce_parameter(self, parameter_1, parameter_2, probability_1=0.5):
        mask_1 = torch.bernoulli(torch.full(parameter_1.shape, probability_1)).int()
        mask_2 = torch.ones(parameter_1.shape).int() - mask_1
        return torch.nn.parameter.Parameter(mask_1 * parameter_1 + mask_2 * parameter_2)

    def reproduce(self, net_1, net_2, probability_1=0.5):
        self.hidden['linear'].weight = self._reproduce_parameter(net_1.hidden['linear'].weight, net_2.hidden['linear'].weight, probability_1)
        self.hidden['linear'].bias = self._reproduce_parameter(net_1.hidden['linear'].bias, net_2.hidden['linear'].bias, probability_1)
        self.output['linear'].weight = self._reproduce_parameter(net_1.output['linear'].weight, net_2.output['linear'].weight, probability_1)
        self.output['linear'].bias = self._reproduce_parameter(net_1.output['linear'].bias, net_2.output['linear'].bias, probability_1)

    def _random_parameter(self, parameter):
        return torch.nn.parameter.Parameter(torch.rand(parameter.shape).to(device) - 0.5)

    def random(self):
        self.hidden['linear'].weight = self._random_parameter(self.hidden['linear'].weight)
        self.hidden['linear'].bias = self._random_parameter(self.hidden['linear'].bias)
        self.output['linear'].weight = self._random_parameter(self.output['linear'].weight)
        self.output['linear'].bias = self._random_parameter(self.output['linear'].bias)


    def add_neuron(self, input):
        raise NotImplemented(f"CrossZeroNet_01.add_neuron")
        # cross_zero_net.hidden_linear.weight = torch.nn.parameter.Parameter(torch.cat((torch.Tensor(cross_zero_net.hidden_linear.weight), torch.Tensor(cross_zero_net.hidden_linear.weight)), dim=0))        #requires_grad=False!
        # cross_zero_net.hidden_linear.bias = torch.nn.parameter.Parameter(torch.cat((torch.Tensor(cross_zero_net.hidden_linear.bias), torch.Tensor(cross_zero_net.hidden_linear.bias)), dim=0))
        # cross_zero_net.output_linear.weight = torch.nn.parameter.Parameter(torch.cat((torch.Tensor(cross_zero_net.output_linear.weight), torch.Tensor(cross_zero_net.output_linear.weight)), dim=1))
        # cross_zero_net.output_linear.bias


class NetCurrent(NetMutate):
    __version = 1



"""# игрок
* вход: как у сети (тензор 1*9, float, значения (-1, 0, 1))
* выход: одно число, int - индекс ячейки в вытянутом тензоре 1*9

## классы

### базовый класс всех игроков
"""


class IPlayer():
    def __init__(self):
        super().__init__()

        self.figure = FIGURES['___']
        self.score = None

    def make_move(self, input):
        pass


class PlayerCheck(IPlayer):
    def make_move(self, input):
        assert (list(input.shape) == [Y_LEN * X_LEN])
        assert (all([(input[i].item() in VALUES_TO_FIGURES) for i in range(input.shape[0])]))

        result = super().make_move(input)
        return result


"""### рандомные ходы в свободные ячейки"""


class PlayerRandom(PlayerCheck):
    def make_move(self, input):
        # super().make_move(input) # отключено для скорости

        # print(input)

        while (True):
            result = np.random.randint(0, Y_LEN * X_LEN)
            # print(result, input[result])
            if (input[result] == 0):  # FIGURES_TO_VALUES['___']
                break

        return result

"""### расчет через сеть"""

class PlayerNet(PlayerCheck):
    def __init__(self,
                 net_class=NetCurrent,
                 hidden_count=2,
                 verbose=False,
                 ):
        super().__init__()

        self.verbose = verbose
        self.net = net_class(hidden_count=hidden_count)

        self.net.to(device)

    def make_move(self, input):
        # super().make_move(input) # отключено для скорости

        result = input
        result = result.to(device)
        # result = result.contiguous().view(-1)

        result = self.net(result)

        result = result.argmax()
        # result = torch.Tensor([result // self.net.y_len, result % self.net.x_len]).type(torch.uint8)

        # assert((result['y'] >=0) and (result['y'] <= self.net.y_len - 1))
        # assert((result['x'] >=0) and (result['x'] <= self.net.x_len - 1))

        return result


class PlayerMutate(PlayerNet):
    def mutate(self, player, probability=0.1, max_volume=0.1):
        self.net.mutate(player.net, probability, max_volume)

    def reproduce(self, player_1, player_2, probability_1=0.5):
        self.net.reproduce(player_1.net, player_2.net, probability_1)

    def random(self):
        self.net.random()


class PlayerCurrent(PlayerMutate):
    __version = 1


"""# представление хода"""


class Presentation():
    # перевод между человеко-читаемым видом (3*3) и сетью (1*9)

    @staticmethod
    def board_from_human_to_net(board):
        return board.contiguous().view(-1)

    @staticmethod
    def board_from_net_to_human(tensor):
        return tensor.reshape(Y_LEN, X_LEN)

    @staticmethod
    def move_from_human_to_net(move):
        return move * Y_LEN + X_LEN

    @staticmethod
    def move_from_net_to_human(move):
        if isinstance(move, torch.Tensor):
            move = move.item()
        return (move // Y_LEN, move % Y_LEN)


"""# популяция

## классы
"""


class IPopulation():
    def __init__(self, num_players, player_class=PlayerCurrent):
        super().__init__()

        self.players = None


class PopulationCheck(IPopulation):
    def __init__(self, num_players, player_class=PlayerCurrent):
        super().__init__(num_players, player_class)

        assert (num_players > 0)
        assert (player_class is not None)


class PopulationBase(PopulationCheck):
    def __init__(self, num_players, player_class=PlayerCurrent, hidden_count=2):
        super().__init__(num_players, player_class)

        self.players = np.array([player_class(hidden_count=hidden_count) for index_player in range(num_players)])


class PopulationMutate(PopulationBase):
    def __init__(self, num_players, player_class=PlayerCurrent, hidden_count=2):
        super().__init__(num_players, player_class, hidden_count)

        self.len_copy = int(0.1 * len(self.players))
        self.len_mutate = int(0.5 * len(self.players))
        self.len_reproduce = int(0.3 * len(self.players))
        self.len_random = int(0.1 * len(self.players))

    def sort_players(self):
        # self.players = sorted(self.players, key=lambda x: x.score, reverse=True)

        # print([p.score for p in self.players])
        # print(torch.cat([p.score for p in self.players]))
        # print(torch.cat([p.score for p in self.players]).argsort(descending=True).tolist())
        self.players = self.players[torch.cat([p.score for p in self.players]).argsort(descending=True).tolist()]

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


    def generate(self):
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


class PopulationCurrent(PopulationMutate):
    __version = 1


"""# проверка линии из одинаковых финур

## классы
"""


class Scoring():
    @classmethod
    def is_line(cls, board, figure_value, win_len=Y_LEN):
        return any([((template * (board == figure_value)).sum().abs() >= abs(win_len * figure_value)) for template in
                    TEMPLATES_WIN])



"""# партия

## классы
"""


class IParty():
    def play_party(self, player_our, player_enemy):
        pass


class PartyCheck(IParty):
    def play_party(self, player_our, player_enemy):
        assert (isinstance(player_our, IPlayer))
        assert (isinstance(player_enemy, IPlayer))

        return super().play_party(player_our, player_enemy)


class PartyBase(PartyCheck):
    def __init__(self,
                 *args,
                 verbose=False,
                 **kwargs,
                 ):
        super().__init__()

        self.verbose = verbose


class PartyFull(PartyBase):
    def play_party(self, player_0, player_1):
        super().play_party(player_0, player_1)

        player_0.figure = 1  # FIGURES_TO_VALUES['_X_']
        player_1.figure = -1  # FIGURES_TO_VALUES['_0_']

        scores_all = [
            {'points': 0, 'win': False, 'invalid': False, 'invalid_enemy': False},
            {'points': 0, 'win': False, 'invalid': False, 'invalid_enemy': False},
        ]

        board = torch.Tensor([
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
        ]).to(device).contiguous().view(-1).type(torch.float)
        board.requires_grad = False

        index_player = 0
        players_all = [player_0, player_1]

        for index_move in range(Y_LEN * X_LEN):
            if self.verbose: print()
            if self.verbose: print(f"index_move={index_move}")
            if self.verbose: print(f"board:\n{Presentation.board_from_net_to_human(board)}")

            player = players_all[index_player]
            score = scores_all[index_player]
            score_enemy = scores_all[(index_player + 1) % 2]

            move = player.make_move(board)
            if self.verbose: print(f"player={player}")
            if self.verbose: print(f"move={Presentation.move_from_net_to_human(move)}")

            if board[move] == 0:  # FIGURES_TO_VALUES['___']
                score['points'] += SCORES_WEIGHTS['valid_move']
            else:
                score['invalid'] = True
                score_enemy['invalid_enemy'] = True
                break

            board[move] = player.figure

            if Scoring.is_line(board, player.figure):
                score['win'] = True

            index_player = (index_player + 1) % 2

        return scores_all


class PartyCurrent(PartyFull):
    __version = 1



"""# вычисление результата одного игрока

## классы
"""


class IEvaluatePlayer():
    def evaluate(self, player):
        pass


class EvaluatePlayerBase(IEvaluatePlayer):
    def __init__(self,
                 *args,
                 num_parties=PARTIES['random'],
                 verbose=False,
                 **kwargs,
                 ):
        super().__init__()

        self.verbose = verbose
        self.num_parties = num_parties


class EvaluatePlayerCheck(EvaluatePlayerBase):
    def evaluate(self, player):
        super().evaluate(player)
        assert (player is not None)


class EvaluatePlayerRandom(EvaluatePlayerCheck):
    def __init__(self,
                 *args,
                 player_enemy_class=PlayerRandom,
                 party_class=PartyCurrent,
                 **kwargs,
                 ):
        super().__init__(**kwargs)

        self.player_enemy = player_enemy_class()
        self.party = party_class()

    def calc_score(self, score):
        result = SCORES_WEIGHTS['win'] * score['win'] + \
                 SCORES_WEIGHTS['valid_move'] * score['points']

        return result

    def evaluate_random(self, player, num_parties_random):
        super().evaluate(player)

        result = None

        # print(f"evaluate_random.begin")
        result = sum([self.calc_score(self.party.play_party(player, self.player_enemy)[0]) for index_party in
                      range(num_parties_random)]) / num_parties_random
        # print(f"evaluate_random.end")

        player.score = result

        # print(scores)

        # for s in scores:
        #     print(self.calc_score(s[0]), s)
        # result = sum([s[0]) for s in scores])

        return result


class EvaluatePlayerFull(EvaluatePlayerRandom):
    def evaluate(self, player):
        super().evaluate(player)

        result = self.evaluate_random(player, self.num_parties)

        return result


class EvaluatePlayerCurrent(EvaluatePlayerFull):
    __version = 1


"""# вычисление результата популяции

## классы
"""


class IEvaluatePopulation():
    def evaluate(self, population):
        pass


class EvaluatePopulationCheck(IEvaluatePopulation):
    def evaluate(self, population):
        super().evaluate(population)
        assert (population is not None)


class EvaluatePopulationBase(EvaluatePopulationCheck):
    def __init__(self, num_parties=PARTIES['random']):
        super().__init__()

        self.num_parties = num_parties
        self.evaluate_player = EvaluatePlayerCurrent(num_parties=num_parties)

    def evaluate(self, population):
        super().evaluate(population)

        [self.evaluate_player.evaluate(player) for player in population.players]

        return population


class EvaluatePopulationCurrent(EvaluatePopulationBase):
    __version = 1



"""# тренировка популяции

## классы
"""


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
            print(f"index_epoch={index_epoch}")

            self.evaluate_population.evaluate(population)
            # print(f"evaluate={[p.score.item() for p in population.players]}")

            population.sort_players()
            top_10 = [f"{p.score.item():.2f} (len={len(p.net.hidden['linear'].weight)}, max={p.net.hidden['linear'].weight.abs().max():.2f})" for p in population.players[:10]]
            print(f"top 10 = {top_10}")

            population.generate()
            # print(f"mutate={[p.score.item() for p in population.players]}")

        return population


class TrainPopulationCurrent(TrainPopulationBase):
    __version = 1


