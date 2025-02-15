# Red-Black Tree in Pact

## Introduction

This repository contains an implementation of a Self-balanced Binary Search Tree (BST)
for Pact.

https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree

https://en.wikipedia.org/wiki/Red%E2%80%93black_tree

This is a very important building block for BRO-Dex and BRO-Finance. And more generally, the best and simplest way to maintain a scalable sorted list.

## License

This module is licensed under Business Source License. Production use by not granted entities is prohibited.

## Usage

### Multi-trees

The module support hosting of multiple trees. Each tree has a guard assigned to it. This guard controls and limits insertion and node removal.

### IDs and Keys

A **unique** ID (*string*) must be assigned to each node. Each node has a key (*decimal*) used for ordering the tree. The ordering is stable, and when two keys are equal: older is first.

### Default node

The tree must never be empty. As such, a default node is created when the tree is initialized.
The default node ID is the hash of the tree's name.

### API
##### `(init-tree)`
`tree` *string* `write-guard` *guard*  `default-key` *decimal* → *bool*

Create a new tree with a given name and write guard.

`default-key` is the key of the Default node: usually the maximal expected value.

##### `(insert-value)`
`tree` *string* `id` *string*  `key` *decimal* → *bool*

Insert a new node in the tree, with an unique ID, and a decimal key used for ordering.

##### `(delete-value)`
`tree` *string* `id`  → *bool*

Delete a value from the tree


##### `(first-node)`
  → *object{node-sch}*

Return the first node (internal representation) of the tree.

##### `(last-node)`
  → *object{node-sch}*

Return the last node (internal representation) of the tree.

##### `(first-value)`
  → *string*

Return the first value (ID) of the tree.

##### `(last-value)`
  → *string*

Return the last value (ID) of the tree.

##### `(next-node current)`
  *object{node-sch}* → *object{node-sch}*

Iterate through the tree.

##### `(prev-node current)`
  *object{node-sch}* → *object{node-sch}*

Iterate through the tree in reverse order.


### Depth parameter

The constant `MAX-DEPTH` defines the maximum depth of the tree.
Since Pact doesn't allow interrupted iterations, this parameter is a tradeoff between:

- Gas Usage
- Maximum number of nodes

The default value of 24 guarantees that at least (worst case) 4095 nodes can be in the tree (but practically the number of allowed nodes is > to 100,000).

Using another value for `MAX-DEPTH` is possible, depending on the expected number of nodes, and gas constraints.


## Gas usage

With `MAX-DEPTH`= 24:

| Tree Size           | 100 nodes | 1000 nodes | 10,000 nodes |
| :-------------------|--------:  |----------: | -----------: |
| Insertion (min)     | 282       | 338        | 385          |
| Insertion (average) | 511       | 558        | 642          |
| Insertion (max)     | 1615      | 1690       | 2202         |
| Removal (min)       | 111       | 111        | 111          |
| Removal (average)   | 379       | 381        | 376          |
| Removal (max)       | 1455      | 1615       | 1615         |

Empirically tested with **Pact 5.0** over:
  - 5,000 insertions/removals for 100 nodes
  - 10,000 insertions/removals for 1000 and 10,000 nodes
