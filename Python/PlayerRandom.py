# -*- coding: utf-8 -*-

import numpy as np

from Common import Y_LEN
from Common import X_LEN
from Common import FIGURES_TO_VALUES

from PlayerBase import PlayerCheck


"""### рандомные ходы в свободные ячейки"""
class PlayerRandom(PlayerCheck):
    def make_move(self, input):
        super().make_move(input)

        # print(input)

        while (True):
            result = np.random.randint(0, Y_LEN * X_LEN)
            # print(result, input[result])
            if (input[result] == FIGURES_TO_VALUES['___']):
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

            if (board[result] == FIGURES_TO_VALUES['___']):
                break

        return result

