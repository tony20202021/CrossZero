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


from Common import Scoring
from Common import Presentation
from Common import Y_LEN
from Common import X_LEN


import torch
print(torch.__version__)

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print(device)

import matplotlib.pyplot as plt

def fill_board(board, figure, data):
    if (board == 0).sum() == 0:
        return

    key = str(board)
    if key not in data:
        data[key] = {
            'board': board,
            'figure': figure,
            'presentation': Presentation.board_from_net_to_human_str(board),
            'valid_moves': (board == 0).astype(int),
            'win': set(),
        }
    else:
        if data[key]['figure'] == figure:
            return

    _data_key = data[key]

    for move in range(9):
        if board[move] == 0:
            new_board = board.copy()
            new_board[move] = figure
            new_figure = (((figure + 2) % 3) * 2) - 1

            if Scoring.is_line(new_board, figure, 3):
                if move in data[key]['win']:
                    a=1
                data[key]['win'].add(move)
                continue

            fill_board(new_board, new_figure, data)

    data[key]['win_list'] = np.zeros(9)
    data[key]['win_list'][list(data[key]['win'])] = 1


data = {}

board = np.zeros(9)
fill_board(board, 1, data)

board = np.zeros(9)
fill_board(board, -1, data)

print(len(data))

X_train = torch.Tensor([data[key]['board'] for key in data])
y_train = torch.Tensor([data[key]['valid_moves'] for key in data])

X_test = torch.Tensor([data[key]['board'] for key in data])
y_test = torch.Tensor([data[key]['valid_moves'] for key in data])

X_train = X_train.reshape(X_train.shape[0], 1, Y_LEN, X_LEN)
y_train = y_train.reshape(y_train.shape[0], 1, Y_LEN, X_LEN)
X_test = X_test.reshape(X_test.shape[0], 1, Y_LEN, X_LEN)
y_test = y_test.reshape(y_test.shape[0], 1, Y_LEN, X_LEN)

print(X_train.shape, y_train.shape, X_test.shape, y_test.shape)


class CrossZeroNet(torch.nn.Module):
    def __init__(self, n_hidden_neurons=None, mid_channels=1):
        super().__init__()

        self.model = torch.nn.Sequential(
            torch.nn.Conv2d(in_channels=1, out_channels=mid_channels, kernel_size=(3, 3), padding=(1, 1)),
            torch.nn.ReLU(),
            torch.nn.Conv2d(in_channels=mid_channels, out_channels=mid_channels, kernel_size=(3, 3), padding=(1, 1)),
            torch.nn.ReLU(),
            torch.nn.Conv2d(in_channels=mid_channels, out_channels=1, kernel_size=(1, 1), padding=(0, 0)),
            torch.nn.Sigmoid()
        )

    def forward(self, x):
        return self.model(x)


class CrossZeroNetDense(torch.nn.Module):
    def __init__(self, n_hidden_neurons=30):
        super().__init__()

        self.model = torch.nn.Sequential(
            torch.nn.Linear(in_features=Y_LEN * X_LEN, out_features=n_hidden_neurons),
            torch.nn.ReLU(),
            torch.nn.Linear(in_features=n_hidden_neurons, out_features=Y_LEN * X_LEN),
            torch.nn.Sigmoid()
        )

    def forward(self, x):
        return self.model(x.reshape(x.shape[0], -1)).reshape(x.shape[0], 1, Y_LEN, X_LEN)


model_class = CrossZeroNet
n_hidden_neurons = None
mid_channels = 30

loss_class = torch.nn.BCELoss
# optimizer = torch.optim.Adam(cross_zero_net.parameters(), 1e-3)

optimizers_all = {
    'Adam':{},
  }

for optimizer_key in optimizers_all:
  optimizers_all[optimizer_key]['model'] = model_class(n_hidden_neurons=n_hidden_neurons, mid_channels=mid_channels).to(device)
  optimizers_all[optimizer_key]['loss_train'] = loss_class()
  optimizers_all[optimizer_key]['loss_test'] = loss_class()
  optimizers_all[optimizer_key]['train_accuracy_history'] = []
  optimizers_all[optimizer_key]['train_loss_history'] = []
  optimizers_all[optimizer_key]['test_accuracy_history'] = []
  optimizers_all[optimizer_key]['test_loss_history'] = []

optimizers_all['Adam']['optimizer'] = torch.optim.Adam(optimizers_all
  ['Adam']['model'].parameters(), lr=1e-4)

print(len(optimizers_all))

# from IPython.display import clear_output
import tqdm


def train_model(configuration, X_train, y_train, X_test, y_test, suptitle, n_epochs=100, n_epochs_plot=10):
    num_train_samples = X_train.shape[0]

    # batch_size = 2
    batch_size = num_train_samples

    # print(X_train)

    for epoch_index in tqdm.tqdm(range(n_epochs)):
        # order = np.random.permutation(num_train_samples)
        # # print(order)

        # X_train = X_train[order]
        # y_train = y_train[order]
        # # print(X_train)

        for batch_start in range(0, num_train_samples, batch_size):
            X_batch = X_train[batch_start: batch_start + batch_size].to(device)
            y_batch = y_train[batch_start: batch_start + batch_size].to(device)
            if (len(X_batch) != batch_size) or (len(y_batch) != batch_size):
                print(batch_start, batch_start + batch_size, batch_size, len(X_batch), len(y_batch))

            # print(X_batch.shape, y_batch.shape)
            for configuration_key in configuration:

                configuration[configuration_key]['model'].train()

                pred = configuration[configuration_key]['model'](X_batch)
                # print(pred.shape, y_batch.shape)

                assert(pred.shape == y_batch.shape)

                predicted_argmax = pred.reshape(pred.shape[0], -1).argmax(1)
                assert(predicted_argmax.shape[0] == pred.shape[0])

                predicted_compare = torch.gather(y_batch.reshape(y_batch.shape[0], -1), 1, predicted_argmax.unsqueeze(1))
                assert(predicted_compare.shape[0] == predicted_argmax.shape[0])

                correct_train = ((predicted_compare == 1).sum() / len(y_batch)).detach()
                assert(correct_train >= 0.0)
                assert(correct_train <= 1.0)

                loss_val = configuration[configuration_key]['loss_train'](pred, y_batch)
                loss_val.backward()

                configuration[configuration_key]['optimizer'].step()
                configuration[configuration_key]['optimizer'].zero_grad()

                if batch_start == 0:
                    configuration[configuration_key]['train_loss_history'].append(loss_val.detach())
                    configuration[configuration_key]['train_accuracy_history'].append(correct_train)

                    # configuration[configuration_key]['model'].eval()
                    # with torch.no_grad():
                    #     test_preds = configuration[configuration_key]['model'](X_test.to(device))
                    #
                    #     assert (test_preds.shape == y_test.shape)
                    #
                    #     predicted_argmax = test_preds.reshape(test_preds.shape[0], -1).argmax(1)
                    #     assert (predicted_argmax.shape[0] == test_preds.shape[0])
                    #
                    #     correct = ((y_test.reshape(y_test.shape[0], -1)[:, predicted_argmax eryreyery] == 1).sum() / len(y_test)).detach()
                    #     assert (correct >= 0.0)
                    #     assert (correct <= 1.0)
                    #
                    #     # print(predicted.shape, y_test.shape)
                    #
                    #     loss_test_val = configuration[configuration_key]['loss_test'](test_preds, y_test.to(device))
                    #     configuration[configuration_key]['test_loss_history'].append(loss_test_val.detach())
                    #     configuration[configuration_key]['test_accuracy_history'].append(correct)

        if (epoch_index % n_epochs_plot) == 0:
            clear_output(True)

            fig, ax = plt.subplots(len(configuration), 2, figsize=(29, 3 * len(configuration)))
            ax = ax.reshape(len(configuration), -1)

            fig.subplots_adjust(hspace=.5)
            fig.suptitle(suptitle, fontsize=20)

            for optimizer_index, configuration_key in enumerate(configuration):
                ax[optimizer_index, 0].set_title(configuration_key)
                ax[optimizer_index, 0].set_xlabel('epochs')
                ax[optimizer_index, 0].set_ylabel('loss')
                ax[optimizer_index, 0].plot(configuration[configuration_key]['train_loss_history'], label=f"train last={np.array(configuration[configuration_key]['train_loss_history'])[-1]:.3f}")
                # ax[optimizer_index, 0].plot(configuration[configuration_key]['test_loss_history'], label=f"test")
                ax[optimizer_index, 0].legend()
                ax[optimizer_index, 0].grid(True)

                ax[optimizer_index, 1].set_title(configuration_key)
                ax[optimizer_index, 1].set_xlabel('epochs')
                ax[optimizer_index, 1].set_ylabel('accuracy')
                ax[optimizer_index, 1].plot(configuration[configuration_key]['train_accuracy_history'],
                                            label=f"train: last={np.array(configuration[configuration_key]['train_accuracy_history'])[-1]:.3f} ")
                # ax[optimizer_index, 1].plot(configuration[configuration_key]['test_accuracy_history'],
                #                             label=f"test: {np.array(configuration[configuration_key]['test_accuracy_history']).max():.3f} ({np.array(configuration[configuration_key]['test_accuracy_history']).argmax()})")
                ax[optimizer_index, 1].legend()
                ax[optimizer_index, 1].grid(True)

            plt.show()



print(optimizers_all['Adam']['model'])


configuration = optimizers_all
n_epochs = 100
n_epochs_plot = 1

train_model(configuration, X_train, y_train, X_test, y_test, suptitle='test', n_epochs=n_epochs, n_epochs_plot=n_epochs_plot)

mid_channels_all = {
    10: {},
    20: {},
    30: {},
    40: {},
}

model_class = CrossZeroNet
n_hidden_neurons = None
# mid_channels = 1

loss_class = torch.nn.BCELoss

learning_rate = 1e-3

for mid_channels in mid_channels_all:
    mid_channels_all[mid_channels]['model'] = model_class(n_hidden_neurons=n_hidden_neurons,
                                                          mid_channels=mid_channels).to(device)
    mid_channels_all[mid_channels]['loss_train'] = loss_class()
    mid_channels_all[mid_channels]['loss_test'] = loss_class()
    mid_channels_all[mid_channels]['train_accuracy_history'] = []
    mid_channels_all[mid_channels]['train_loss_history'] = []
    mid_channels_all[mid_channels]['test_accuracy_history'] = []
    mid_channels_all[mid_channels]['test_loss_history'] = []

    mid_channels_all[mid_channels]['optimizer'] = torch.optim.Adam(mid_channels_all[mid_channels]['model'].parameters(),
                                                                   lr=learning_rate)

print(len(mid_channels_all))


configuration = mid_channels_all
n_epochs = 100
n_epochs_plot = 1

train_model(configuration, X_train, y_train, X_test, y_test, suptitle='mid_channels_all', n_epochs=n_epochs, n_epochs_plot=n_epochs_plot)

n_hidden_neurons_all = {
    10: {},
    20: {},
    30: {},
    40: {},
}

model_class = CrossZeroNetDense

loss_class = torch.nn.BCELoss

learning_rate = 1e-3

for n_hidden_neurons in n_hidden_neurons_all:
    n_hidden_neurons_all[n_hidden_neurons]['model'] = model_class(n_hidden_neurons=n_hidden_neurons).to(device)
    n_hidden_neurons_all[n_hidden_neurons]['loss_train'] = loss_class()
    n_hidden_neurons_all[n_hidden_neurons]['loss_test'] = loss_class()
    n_hidden_neurons_all[n_hidden_neurons]['train_accuracy_history'] = []
    n_hidden_neurons_all[n_hidden_neurons]['train_loss_history'] = []
    n_hidden_neurons_all[n_hidden_neurons]['test_accuracy_history'] = []
    n_hidden_neurons_all[n_hidden_neurons]['test_loss_history'] = []

    n_hidden_neurons_all[n_hidden_neurons]['optimizer'] = torch.optim.Adam(
        n_hidden_neurons_all[n_hidden_neurons]['model'].parameters(), lr=learning_rate)

print(len(n_hidden_neurons_all))


configuration = n_hidden_neurons_all
n_epochs = 400
n_epochs_plot = 1

train_model(configuration, X_train, y_train, X_test, y_test, suptitle='n_hidden_neurons_all', n_epochs=n_epochs, n_epochs_plot=n_epochs_plot)


from Population import PopulationCurrent
from EvaluatePopulation import EvaluatePopulationCurrent
from TrainPopulation import TrainPopulationCurrent


train_population = TrainPopulationCurrent(num_parties=100, evaluate_population_class=EvaluatePopulationCurrent, num_epoch=2000)
# print(train_population)

population = PopulationCurrent(num_players=1, hidden_count=30)
# print(population)

print(train_population.train(population))


