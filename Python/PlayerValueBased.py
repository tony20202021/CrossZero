# -*- coding: utf-8 -*-
# import matplotlib.pyplot as plt

import numpy as np
import random
import collections
import typing

import torch

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

from Common import PlayerCheck
from Common import Presentation
from Common import SCORES_WEIGHTS

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
        return tuple(board)

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

                if (key_state == key):
                    calc_result =  {
                        'value': 0,
                        'is_changed': False,
                        'is_full_known': True,
                    }
                else:
                    calc_result = self._calc_value(key_state)

                state['calc_result'] = calc_result['value']
                new_value += (state['percent']) * (state['EMA'] + calc_result['value'])
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
            # self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['scores'].append(self.previous_move_score)
            # self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['mean'] = \
            #     np.mean(self.data[previous_key]['all_moves'][self.previous_move]['next_states'][key]['scores'])
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
                    for index in range(len(board)) # if board[index].item() == 0
                }, # FIGURES_TO_VALUES['___']
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

        self.previous_move_score = score_move

    def begin_party(self):
        self.previous_board = None
        self.previous_move = None
        self.previous_move_score = None

    def end_party(self, board, score):
        assert (self.previous_board is not None)
        assert (self.previous_move is not None)
        assert (self.previous_move_score is not None)

        if score['lose']:
            self.previous_move_score = SCORES_WEIGHTS['lose']
        self.update_previous_move(board, is_full_known=True)

        self.party_score = score

        self.previous_board = None
        self.previous_move = None
        self.previous_move_score = None



class PlayerCurrent(PlayerValueBased):
    __version = 2

