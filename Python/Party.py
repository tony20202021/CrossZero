# -*- coding: utf-8 -*-

"""
партия
"""

import numpy as np

from Common import FIGURES_TO_VALUES
from Common import SCORES_WEIGHTS
from Common import Presentation
from Common import Scoring
from PlayerBase import IPlayer

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

        player_0.figure = FIGURES_TO_VALUES['_X_']
        player_1.figure = FIGURES_TO_VALUES['_0_']

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

            is_valid = (board[move] == FIGURES_TO_VALUES['___'])
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

            if not is_valid:
                break

            board = next_board

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



