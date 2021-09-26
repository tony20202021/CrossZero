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
    # 'valid_move': torch.Tensor([1]).to(device).type(torch.float),
    'valid_move': torch.Tensor([0]).to(device).type(torch.float),
    'win': torch.Tensor([100]).to(device).type(torch.float),
    # 'win': torch.Tensor([0]).to(device).type(torch.float),
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

    def get_info(self):
        return f"hidden:{len(self.net.hidden['linear'].weight)}"

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


class PlayerValueBased(PlayerCheck):
    def __init__(self,
                 *args,
                 verbose=False,
                 **kwargs,
                 ):
        super().__init__()

        self.verbose = verbose
        self.data = {}
        self.data_is_full_known = False
        self.party_score = None
        self.previous_board = None
        self.previous_move_score = None
        self.train = None

    def _calc_key(self, board):
        return tuple(board.int().tolist())

    def get_info(self):
        return f"len={len(self.data)}, {self.data_is_full_known}"

    def set_train(self, train):
        self.train = train

    def _calc_value(self, key):
        if key not in self.data.keys():
            return {
                'value': 0,
                'is_changed': False,
                'is_full_known': False,
            }
        # TODO
        if (self.data[key]['is_full_known']) and ('all_moves' not in self.data[key]):
            return {
                'value': self.data[key]['value'],
                'is_changed': False,
                'is_full_known': True,
            }

        _data_current_key = self.data[key]

        self.data[key]['is_changed'] = False
        self.data[key]['is_full_known'] = True
        for key_move, move in self.data[key]['all_moves'].items():
            _move = move

            new_value = 0
            is_changed = False
            is_full_known = True
            for key_state, state in move['next_states'].items():
                _state = state
                _data_new_key = self.data[key_state]

                state['percent'] = state['count'] / move['next_states_count']

                calc_result = self._calc_value(key_state)
                state['calc_result'] = calc_result['value']
                new_value += (state['percent']) * (state['mean'] + calc_result['value'])
                is_changed = is_changed or calc_result['is_changed']
                is_full_known = is_full_known and calc_result['is_full_known']

            if move['next_states_count'] > 0:
                move['is_full_known'] = is_full_known
                move['is_changed'] = is_changed or (move['value'] != new_value)
                move['value'] = new_value
            else:
                move['is_full_known'] = False
                move['is_changed'] = False
                move['value'] = None

            self.data[key]['is_changed'] = self.data[key]['is_changed'] or move['is_changed']
            self.data[key]['is_full_known'] = self.data[key]['is_full_known'] and move['is_full_known']

        not_null = np.array([move['value'] for move in self.data[key]['all_moves'].values() if move['value'] is not None])
        if len(not_null) > 0:
            best_known = not_null.argmax()
            self.data[key]['best_move'] = list(self.data[key]['all_moves'].keys())[best_known]
            self.data[key]['value'] = self.data[key]['all_moves'][self.data[key]['best_move']]['value']
        else:
            self.data[key]['value'] = None

        return {
            'value': self.data[key]['value'],
            'is_changed': self.data[key]['is_changed'],
            'is_full_known': self.data[key]['is_full_known'],
        }


    def update(self):
        is_changed = True
        while is_changed:
            is_changed = False
            self.data_is_full_known = True
            for key in self.data:
                calc_result = self._calc_value(key)
                is_changed = is_changed or calc_result['is_changed']
                self.data_is_full_known = self.data_is_full_known and calc_result['is_full_known']

        if self.data_is_full_known:
            a = False
            if a:
                self.data = dict(sorted(self.data.items()))


    def update_previous_move(self, board, is_full_known):
        key = self._calc_key(board)
        if (self.previous_board is not None) or (self.previous_move is not None) or (self.previous_move_score is not None):
            assert(self.previous_board is not None)
            assert(self.previous_move is not None)
            assert(self.previous_move_score is not None)

            previous_key = self._calc_key(self.previous_board)

            assert(previous_key in self.data)
            assert(self.previous_move in self.data[previous_key]['all_moves'])

            self.data[previous_key]['all_moves'][self.previous_move]['next_states_count'] += 1
            if key not in self.data[previous_key]['all_moves'][self.previous_move]['next_states']:
                self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key] = {
                        'calc_result': None,
                        'count': 0,
                        'percent': None,
                        'mean': None,
                        'EMA': 0,
                        'last_score': None,
                        'present': Presentation.board_from_net_to_human_str(board),
                        'scores': [],
                        'is_full_known': False,
                        'board': board,
                }
            alpha = 0.5

            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['count'] += 1
            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['last_score'] = self.previous_move_score
            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['scores'].append(self.previous_move_score)
            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['mean'] = \
                np.mean(self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['scores'])
            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['EMA'] = \
                (1-alpha)*(self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['EMA']) + \
                (alpha) * self.previous_move_score
            self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['is_full_known'] = is_full_known

            if is_full_known and (key not in self.data):
                self.data[key] = {
                    'value': 0,
                    'is_changed': False,
                    'is_full_known': True,
                }

    def make_move(self, board):
        self.update_previous_move(board, is_full_known=False)

        key = self._calc_key(board)
        if key not in self.data:
            self.data[key] = {
                'present': Presentation.board_from_net_to_human_str(board),
                'value': None,
                'best_move': None,
                'is_full_known': False,
                'all_moves': {index:
                    {
                        'value': None,
                        'is_full_known': False,
                        'next_states_count': 0,
                        'next_states': {},
                    }
                    for index in range(len(board)) if board[index].item() == 0}, # FIGURES_TO_VALUES['___']
                'board': board,
            }
            all_moves = list(self.data[key]['all_moves'].keys())
            result = all_moves[0]
        else:
            unknown = [index for index, move in self.data[key]['all_moves'].items() if not move['is_full_known']]
            if len(unknown) > 0:
                result = unknown[0]
            else:
                if self.train or (not self.data_is_full_known):
                    counts = [move['next_states_count'] for index, move in self.data[key]['all_moves'].items()]
                    result = list(self.data[key]['all_moves'].keys())[np.argmin(counts)]
                else:
                    result = self.data[key]['best_move']

        self.previous_board = board
        self.previous_move = result
        self.previous_move_score = None

        return result

    def set_move_score(self, board, move, score_move):
        assert((self.previous_board == board).all())
        assert(self.previous_move == move)
        assert(self.previous_move_score is None)

        self.previous_move_score = score_move.int().item()

    def begin_party(self):
        self.previous_board = None
        self.previous_move = None
        self.previous_move_score = None

    def end_party(self, board, score):
        assert (self.previous_board is not None)
        assert (self.previous_move is not None)
        assert (self.previous_move_score is not None)

        self.update_previous_move(board, is_full_known=True)

        self.party_score = score

        self.previous_board = None
        self.previous_move = None
        self.previous_move_score = None


class PlayerCurrent(PlayerValueBased):
    __version = 2


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
    def board_from_net_to_human_str(tensor):
        result = tensor.reshape(Y_LEN, X_LEN).int().numpy()
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
        self.players = self.players[torch.cat([torch.Tensor([p.score]) for p in self.players]).argsort(descending=True).tolist()]


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

        history = []

        index_player = 0
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

            next_board = board.clone()
            next_board[move] = player.figure

            is_valid = (board[move] == 0)  # FIGURES_TO_VALUES['___']
            is_line = Scoring.is_line(next_board, player.figure)

            score_move = 0
            if is_valid:
                score_move += SCORES_WEIGHTS['valid_move']
            else:
                score['invalid'] = True
                score_enemy['invalid_enemy'] = True

            if is_line:
                score['win'] = True
                score_move += SCORES_WEIGHTS['win']

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



"""# вычисление результата одного игрока

## классы
"""


class IEvaluatePlayer():
    def evaluate(self, player, train):
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
    def evaluate(self, player, train):
        super().evaluate(player, train)
        assert (player is not None)


class EvaluatePlayerRandom(EvaluatePlayerCheck):
    def __init__(self,
                 *args,
                 # player_enemy_class=PlayerRandom,
                 player_enemy_class=PlayerRandomNotCenter,
                 party_class=PartyCurrent,
                 **kwargs,
                 ):
        super().__init__(**kwargs)

        self.player_enemy = player_enemy_class()
        self.party = party_class()

    def calc_score(self, score):
        # result = SCORES_WEIGHTS['win'] \
        #          # * score['win'] + \
        #          # SCORES_WEIGHTS['valid_move'] * score['points']
        result = int(score['win'])

        return result

    def evaluate_random(self, player, num_parties_random):

        result = None

        # print(f"evaluate_random.begin")
        all_parties = [self.calc_score(self.party.play_party(player, self.player_enemy)[0]) for index_party in range(num_parties_random)]
        result = sum(all_parties) / num_parties_random
        # print(f"evaluate_random.end")

        # print(scores)

        # for s in scores:
        #     print(self.calc_score(s[0]), s)
        # result = sum([s[0]) for s in scores])

        return result


class EvaluatePlayerFull(EvaluatePlayerRandom):
    def evaluate(self, player, train):
        super().evaluate(player, train)

        player.set_train(train)
        result = self.evaluate_random(player, self.num_parties)

        player.score = result

        return result

class EvaluatePlayerCurrent(EvaluatePlayerFull):
    __version = 1


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

            self.evaluate_population.evaluate(population, train=True)

            self.evaluate_population.evaluate(population, train=False)
            # print(f"evaluate={[p.score.item() for p in population.players]}")

            population.sort_players()
            top_10 = [f"{p.score:.2f} ({p.get_info()})" for p in population.players[:10]]
            print(f"top 10 = {top_10}")

            population.update()
            # print(f"mutate={[p.score.item() for p in population.players]}")

        return population


class TrainPopulationCurrent(TrainPopulationBase):
    __version = 1


