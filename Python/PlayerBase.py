# -*- coding: utf-8 -*-

"""
базовый класс всех игроков
* вход: как у сети (тензор 1*9, float, значения (-1, 0, 1))
* выход: одно число, int - индекс ячейки в вытянутом тензоре 1*9
"""

from Common import FIGURES
from Common import Y_LEN
from Common import X_LEN
from Common import VALUES_TO_FIGURES


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

