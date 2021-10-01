# -*- coding: utf-8 -*-

"""
# вычисление результата одного игрока
"""

from Common import PARTIES
from PlayerRandom import PlayerRandom
from Party import PartyCurrent


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
                 player_enemy_class=PlayerRandom,
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
        all_parties = [self.party.play_party(player, self.player_enemy) for index_party in range(num_parties_random)]
        result = {
            'score': sum([self.calc_score(party[0]) for party in all_parties]) / num_parties_random,
            'win': sum([party[0]['win'] for party in all_parties]) / num_parties_random,
            'lose': sum([party[0]['lose'] for party in all_parties]) / num_parties_random,
            'draw': sum([party[0]['draw'] for party in all_parties]) / num_parties_random,
            'invalid': sum([party[0]['invalid'] for party in all_parties]) / num_parties_random,
        }
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

