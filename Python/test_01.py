from common import PopulationCurrent
from common import EvaluatePopulationCurrent
from common import TrainPopulationCurrent


train_population = TrainPopulationCurrent(num_parties=10, evaluate_population_class=EvaluatePopulationCurrent, num_epoch=10)
# print(train_population)

population = PopulationCurrent(10)
# print(population)

print(train_population.train(population))

