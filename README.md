# Red-Black Tree in Pact

## Introduction

This repository contains an implementation of a Self-balanced Binary Search Tree (BST)
for Pact.

https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree

https://en.wikipedia.org/wiki/Red%E2%80%93black_tree

This is a very import builing block for BRO-Dex and BRO-Finance. And more generally, the best and simplest way to maintain a scalable sorted list.

## License

This module is licensed under Business Source License. Poduction use by not grantend entities is prohibited.

## Usage

### Multi-trees

The module supports hosting of multiple trees. Each tree has a guard assigned. This guards controls and limits insertion and node removals.

### IDs and Keys

An **unique** ID (*string*) must be assigned to each node. Each node has a key (*decimal*) used for ordering the tree. The ordering is stable, and when two keys are equal: older is first.

### Default node

The tree must never be empty. As such a default node is created when the tree is initialized.
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

Return the first node (internal represantation) of the tree.

##### `(last-node)`
  → *object{node-sch}*

Return the last node (internal represantation) of the tree.

##### `(first-value)`
  → *string*

Return the first value (ID) of the tree.

##### `(last-value)`
  → *string*

Return the last value (ID) of the tree.

##### `(next-node current)`
  *object{node-sch}* → *object{node-sch}*

Iteate through the tree.

##### `(prev-node current)`
  *object{node-sch}* → *object{node-sch}*

Iteate through the tree in reverse order.


### Depth parameter

The constant `MAX-DEPTH` defines the maximum depth of the tree.
Since Pact doesn't allow interrupted iterations, this parameter is a tradeoff betwenn:

- Gas Usage
- Maximum number of nodes

The default value of 24 guarantees that at least (worst case) 4095 nodes can be in the tree (but pratically the number of allowed node is > to 100,000).

Using another value for `MAX-DEPTH` is possible dependending on the expected number of nodes, and gas constraints.


## Gas usage

With `MAX-DEPTH`= 24:

| Tree Size           | 100 nodes | 1000 nodes | 10,000 nodes |
| :-------------------|--------:  |----------: | -----------: |
| Insertion (min)     | 950       | 1000       | 1040         |
| Insertion (average) | 1490      | 1560       | 1680         |
| Insertion (max)     | 3980      | 4620       | 6400         |
| Removal (min)       | 390       | 390        | 390          |
| Removal (average)   | 1260      | 1260       | 1260         |
| Reomval (max)       | 4410      | 5200       | 5200         |

Empirically tested over:
  - 5,000 insertions/removals for 100 nodes
  - 10,000 insertions/removals for 1000 and 10,000 nodes
