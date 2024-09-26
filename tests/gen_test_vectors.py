from decimal import Decimal
import random
import argparse



MULT = Decimal("0.1")
to_dec = lambda x:Decimal(x)*MULT


parser = argparse.ArgumentParser(prog='gen_test_vectors')
parser.add_argument('init', type=int, help='Init values count')
parser.add_argument('per_iteration', type=int, help='Per itreration values count')
args = parser.parse_args()

INIT = args.init
PER_ITERATION = args.per_iteration
TO_INSERT_TOTAL= INIT + PER_ITERATION * 100

random.seed("Seed:{:d}:{:d}".format(INIT, PER_ITERATION))

def print_defconst_insert(name, data):
    vals = map(str, map(to_dec, data))
    vals_str = map('"{!s}"'.format, map(to_dec, data))

    print("(defconst KEYS-{:s}:[decimal] [{}])".format(name, ",".join(vals)))
    print("(defconst REFS-{:s}:[string] [{}])".format(name, ",".join(vals_str)))
    print("(defconst LENGTH-{:s}:integer {:d})".format(name, len(data)))

def print_defconst_remove(name, data):
    vals = map(str, map(to_dec, data))
    vals_str = map('"{!s}"'.format, map(to_dec, data))
    print("(defconst REFS-REMOVE-{:s}:[string] [{}])".format(name, ",".join(vals_str)))
    print("(defconst LENGTH-REMOVE-{:s}:integer {:d})".format(name, len(data)))


lst = list(range(TO_INSERT_TOTAL))
random.shuffle(lst)
in_tree = []

print("(module test-vectors G")
print("(defcap G() true)")

in_tree += lst[0:INIT]
lst = lst[INIT:]
print_defconst_insert("TEST-100-INIT", in_tree)

for i in range(100):
    to_insert = lst[-PER_ITERATION:]
    lst = lst[:-PER_ITERATION]
    in_tree += to_insert
    random.shuffle(in_tree)
    to_remove = in_tree[-PER_ITERATION:]
    in_tree = in_tree[:-PER_ITERATION]
    print_defconst_insert("TEST-100-{:d}".format(i), to_insert)
    print_defconst_remove("TEST-100-{:d}".format(i), to_remove)


print(")")
