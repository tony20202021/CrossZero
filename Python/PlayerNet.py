# -*- coding: utf-8 -*-

"""
Игрок на основе нейросети
"""

import collections

import torch
device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

from Common import Y_LEN
from Common import X_LEN
from PlayerBase import PlayerCheck


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

