# -*- coding: utf-8 -*-

import numpy as np

import torch
device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")


"""
глобальные константы
"""

# scores
SCORES_WEIGHTS = {
    'valid_move': 0,
    'invalid_move': -1e5,
    'win': 100,
    'lose': -1e5,
}

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


class Presentation():
    """
    представление хода
    # перевод между человеко-читаемым видом (3*3) и сетью (1*9)
    """

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


class Scoring():
    """
    проверка линии из одинаковых финур
    """

    @classmethod
    def is_line(cls, board, figure_value, win_len=Y_LEN):
        return any([(abs((template * (board == figure_value)).sum()) >= abs(win_len * figure_value)) for template in TEMPLATES_WIN])



