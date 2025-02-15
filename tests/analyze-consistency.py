import json
import sys
from itertools import pairwise
from more_itertools import ilen
import re

def extract_out(lines_in):
    out_re = re.compile('.*"OUT:(.*)"')
    for l in lines_in:
        m = out_re.match(l)
        if m:
            yield m.group(1)

to_str = "{0[key]:.3f} => '{0[value]:s}'".format

def walk_tree(node_id):
    if node_id == "NIL":
        return
    node = nodes[node_id]
    yield from walk_tree(node['left-child'])
    yield node
    yield from walk_tree(node['right-child'])

def _analyze_double_reds(node_id, parent_is_red):
    if node_id == "NIL":
        return
    node = nodes[node_id]
    is_red = node['red']

    if is_red and parent_is_red:
        print("Red violation for {}".format(node['id']))

    _analyze_double_reds(node['left-child'], is_red)
    _analyze_double_reds(node['right-child'], is_red)

current_blacks_count = 0

def _analyze_black_path(node_id, blacks_count):
    global current_blacks_count
    if node_id == "NIL":
        if current_blacks_count  and blacks_count != current_blacks_count:
            print("Blacks Violation {:d} != {:d}".format(current_blacks_count, blacks_count))
        current_blacks_count = blacks_count
        return

    node = nodes[node_id]
    is_black = not node['red']

    blacks_count = blacks_count + (1 if is_black else 0)

    _analyze_black_path(node['left-child'], blacks_count)
    _analyze_black_path(node['right-child'], blacks_count)

def _compute_depth(node_id, cur_depth):
    if node_id == "NIL":
        return cur_depth
    node = nodes[node_id]

    return max(_compute_depth(node['left-child'], cur_depth +1),
               _compute_depth(node['right-child'], cur_depth +1))

def compute_depth():
    print("Analyze depth")
    depth = _compute_depth(data['root'], 0)
    print("Depth={}".format(depth))


def anaylze_data_order():
    print("Analyze data order")
    cnt = 0
    for a,b in pairwise(walk_tree(data['root'])):
        cnt += 1
        if a['key'] > b['key']:
            print("Order error between: {} {}".format(to_str(a),to_str(b) ))
    print("{} pairs analyzed".format(cnt))

def analyze_double_reds():
    print("Analyze double reds")
    _analyze_double_reds(data['root'], False)

def analyze_black_path():
    global current_blacks_count
    current_blacks_count = 0
    print("Analyze Black paths")
    _analyze_black_path(data['root'], 0)
    print("Constant path found {}".format(current_blacks_count))

def print_node_data(node_id):
    for st in  map(to_str, walk_tree(node_id)):
        print(st)

def print_sep():
    print("-------------------------")


nodes = {}
iteration = 0

for line in extract_out(sys.stdin):
    try:
        data = json.loads(line)
    except:
        continue
    for n in data['tree']:
        id = n['id']
        nodes[id] = n
    print("=========================================================")
    print("*** ITERATION:{:d}".format(iteration))
    print("=========================================================")

    print_sep()
    analyze_double_reds()
    print_sep()
    analyze_black_path()
    print_sep()
    anaylze_data_order()
    print_sep()
    compute_depth()
    iteration += 1
