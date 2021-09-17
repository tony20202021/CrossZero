import pandas as pd
import numpy as np
desired_width = 620
pd.set_option('display.width', desired_width)
np.set_printoptions(linewidth=desired_width)


from common import PopulationCurrent
from common import EvaluatePopulationCurrent
from common import TrainPopulationCurrent


train_population = TrainPopulationCurrent(num_parties=10, evaluate_population_class=EvaluatePopulationCurrent, num_epoch=10)
# print(train_population)

population = PopulationCurrent(10)
print([p.net.hidden['linear'].weight for p in population.players])

# print(population)

print(train_population.train(population))

print([p.score for p in population.players])

print([p.net.hidden['linear'].weight for p in population.players])

population.mutate()

print([p.net.hidden['linear'].weight for p in population.players])

print([p.score for p in population.players])
