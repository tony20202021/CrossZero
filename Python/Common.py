# -*- coding: utf-8 -*-
# import matplotlib.pyplot as plt

import numpy as np
import random
import collections
import typing

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
    'valid_move': 0,
    'invalid_move': -1e5,
    'win': 100,
    'lose': -1e5,
}

# parties
PARTIES = {
    'random': 10,
}

MAX_MOVES = 5

SCORE_DIGITS = 2

# templates
TEMPLATES_WIN = np.array([
    [[1, 1, 1],
     [0, 0, 0],
     [0, 0, 0]],
    [[0, 0, 0],
     [1, 1, 1],
     [0, 0, 0]],
    [[0, 0, 0],
     [0, 0, 0],
     [1, 1, 1]],
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
])
TEMPLATES_WIN = TEMPLATES_WIN.reshape(TEMPLATES_WIN.shape[0], -1)


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

    def get_info(self):
        pass

    def make_move(self, input):
        pass

    def begin_party(self):
        pass

    def end_party(self, board, score):
        pass

    def set_move_score(self, board, move, score_move):
        pass

    def set_party_score(self, score):
        pass

    def set_train(self, train):
        pass


class PlayerCheck(IPlayer):
    def make_move(self, input):
        assert (input.shape[0] == Y_LEN * X_LEN)
        assert (all([(input[i] in VALUES_TO_FIGURES) for i in range(input.shape[0])]))

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

"""### рандомные ходы в свободные ячейки, кроме центра"""
class PlayerRandomNotCenter(PlayerCheck):
    _CENTER = 4
    def make_move(self, board):
        super().make_move(board)

        # print(input)
        count_free = sum(board == 0)

        while (True):
            result = np.random.randint(0, Y_LEN * X_LEN)
            # print(result, input[result])

            if (result == self._CENTER) and (count_free > 1):
                continue

            if (board[result] == 0):  # FIGURES_TO_VALUES['___']
                break

        return result


"""# представление хода"""
class Presentation():
    # перевод между человеко-читаемым видом (3*3) и сетью (1*9)

    @staticmethod
    def board_from_human_to_net(board):
        return board.reshape(-1)

    @staticmethod
    def board_from_net_to_human(tensor):
        return tensor.reshape(Y_LEN, X_LEN)

    @staticmethod
    def board_from_net_to_human_str(tensor):
        result = tensor.reshape(Y_LEN, X_LEN)
        result = list(np.vectorize(VALUES_TO_FIGURES.get)(result))
        return result

    @staticmethod
    def move_from_human_to_net(move):
        return move * Y_LEN + X_LEN

    @staticmethod
    def move_from_net_to_human(move):
        if isinstance(move, torch.Tensor):
            move = move.item()
        return (move // Y_LEN, move % Y_LEN)


"""# проверка линии из одинаковых финур

## классы
"""


class Scoring():
    @classmethod
    def is_line(cls, board, figure_value, win_len=Y_LEN):
        return any([(abs((template * (board == figure_value)).sum()) >= abs(win_len * figure_value)) for template in TEMPLATES_WIN])



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

        # 2329 + 196 = 4291
        index_player = np.random.randint(0, 1 + 1)
        # index_player = 1

        player_0.figure = 1  # FIGURES_TO_VALUES['_X_']
        player_1.figure = -1  # FIGURES_TO_VALUES['_0_']

        scores_all = [
            {'points': 0, 'win': False, 'lose': False, 'draw': False, 'invalid': False, 'invalid_enemy': False},
            {'points': 0, 'win': False, 'lose': False, 'draw': False, 'invalid': False, 'invalid_enemy': False},
        ]

        board = np.array([
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
        ])
        board = Presentation.board_from_human_to_net(board)

        history = []

        players_all = [player_0, player_1]

        player_0.begin_party()
        player_1.begin_party()

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

            next_board = board.copy()
            next_board[move] = player.figure

            is_valid = (board[move] == 0)  # FIGURES_TO_VALUES['___']
            is_line = Scoring.is_line(next_board, player.figure)

            score_move = 0
            if is_valid:
                score_move += SCORES_WEIGHTS['valid_move']
            else:
                score_move += SCORES_WEIGHTS['invalid_move']
                score['invalid'] = True
                score_enemy['invalid_enemy'] = True

            if is_line:
                score['win'] = True
                score_move += SCORES_WEIGHTS['win']
                score_enemy['lose'] = True

            player.set_move_score(board, move, score_move)
            score['points'] += score_move

            history.append({
                'player': index_player,
                'move': move,
                'board': board,
                'next_board': next_board,
                'is_valid': is_valid,
                'is_line': is_line,
                'score_move': score_move,
            })

            board = next_board

            if not is_valid:
                break

            if is_line:
                break

            index_player = (index_player + 1) % 2

        if (scores_all[0]['win']): assert(scores_all[1]['lose'])
        if (scores_all[0]['lose']): assert(scores_all[1]['win'])

        if (scores_all[1]['win']): assert(scores_all[0]['lose'])
        if (scores_all[1]['lose']): assert(scores_all[0]['win'])

        assert(not (scores_all[0]['win'] and scores_all[1]['win']))
        assert(not (scores_all[0]['lose'] and scores_all[1]['lose']))

        draw = ((not scores_all[0]['win']) and (not scores_all[1]['win']))
        scores_all[0]['draw'] = draw
        scores_all[1]['draw'] = draw

        player_0.end_party(board, scores_all[0])
        player_1.end_party(board, scores_all[1])

        if (player_0.data_is_full_known) and (not scores_all[0]['win']) and (not player_0.train):
            a = False
            if a:
                index_player = 0
                for index_move, history_move in enumerate(history):
                    if index_player == 0:
                        board = history_move['board']
                        move = player_0.make_move(board)
                        player_0.set_move_score(board, move, history_move['score_move'])

                    index_player = (index_player + 1) % 2

        return scores_all






class PartyCurrent(PartyFull):
    __version = 1



