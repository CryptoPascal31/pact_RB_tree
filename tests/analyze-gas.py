import json
import sys
from itertools import pairwise
from more_itertools import ilen


def print_stats(name, vals, vals_total):
    print(name)
    print("----------")
    print("min:{:d} / {:d}".format(min(vals), min(vals_total)))
    print("avg:{:d} / {:d}".format(sum(vals) // len(vals), sum(vals_total) // len(vals_total)))
    print("max:{:d} / {:d}".format(max(vals), max(vals_total)))
    print(" ")


total_insert = []
total_remove = []
iteration = 0

for line in sys.stdin:
    try:
        data = json.loads(line)

    except:
        continue
    total_insert += data['insert']
    total_remove += data['remove']

    print("=========================================================")
    print("*** ITERATION:{:d}".format(iteration))
    print("=========================================================")
    print_stats("Insertion", data['insert'], total_insert)
    print_stats("Removal", data['remove'], total_remove)

    iteration += 1
