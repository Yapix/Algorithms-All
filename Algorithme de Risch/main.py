from Symbol import Symbol
from Polynomial import Polynomial

x = Symbol()
x.implement_variable('x')

nb_2 = Symbol(2)
nb_3 = Symbol(3)
nb_8 = Symbol(8)
nb_9 = Symbol(9)
nb_9b = Symbol(9)
nb_9b.print_status()
nb_9b.to_int()

poly1 = Polynomial([nb_2, nb_8, nb_3, nb_9, nb_9b])
