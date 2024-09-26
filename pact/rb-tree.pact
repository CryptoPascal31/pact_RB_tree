(module rb-tree GOVERNANCE
  ;SPDX-License-Identifier: BUSL-1.1
  ; --------------------------- CAPABILITIES -----------------------------------
  ; ----------------------------------------------------------------------------
  (defcap GOVERNANCE ()
    (enforce-keyset "RB_TREE_NS.rb_tree_governance"))

  (defcap INIT-TREE ()
    (enforce-keyset "RB_TREE_NS.rb_tree_op")
    (compose-capability (WRITE-TREE)))

  (defcap WRITE-TREE ()
    true)

  (defcap INSERT-DELETE ()
    (compose-capability (WRITE-TREE)))

  ; --------------------------- CONSTANTS --------------------------------------
  ; ----------------------------------------------------------------------------
  (defconst NIL "NIL")

  (defconst MAX-DEPTH 24)

  (defconst ENUM-DEPTH:[integer] (enumerate 0 MAX-DEPTH))
  (defconst ENUM-HALF-DEPTH:[integer] (enumerate 0 (/ MAX-DEPTH 2)))

  ; --------------------------- DATA AND TABLES --------------------------------
  ; ----------------------------------------------------------------------------
  ; Trees definition
  (defschema tree-sch
    root:string
    write-guard:guard
  )
  (deftable trees:{tree-sch})

  ; Node definition
  (defschema node-sch
    id:string ; Node ID
    t:string ; Tree name
    key:decimal ; Ordering key
    parent:string ; Parent ID
    left-child:string ; Left child ID
    right-child:string ; Right child ID
    red:bool ; True if RED, False if BLACK
  )

  (defconst NIL-NODE {'id:NIL, 'key:0.0, 't:"", 'red:false,
                      'parent:NIL, 'left-child:NIL, 'right-child:NIL})

  (deftable nodes:{node-sch})

  ; ------------------- READ ONLY UTIL FUNCTIONS -------------------------------
  ; ----------------------------------------------------------------------------
  (defun get-node:object{node-sch} (ref:string)
    (read nodes ref))

  (defun get-root:object{node-sch} (tree:string)
    (with-read trees tree {'root:=root}
      (get-node root)))

  (defun parent:object{node-sch} (x:object{node-sch})
    (get-node (at 'parent x)))

  (defun left-child:object{node-sch} (x:object{node-sch})
    (get-node (at 'left-child x)))

  (defun left-child*:object{node-sch} (x:object{node-sch})
    (let ((child-ref (at 'left-child x)))
      (if (!= child-ref NIL) (get-node child-ref) x)))

  (defun left-child**:object{node-sch} (x:object{node-sch} _:integer)
    (left-child* x))

  (defun right-child:object{node-sch} (x:object{node-sch})
    (get-node (at 'right-child x)))

  (defun right-child*:object{node-sch} (x:object{node-sch})
    (let ((child-ref (at 'right-child x)))
      (if (!= child-ref NIL) (get-node child-ref) x)))

  (defun right-child**:object{node-sch} (x:object{node-sch} _:integer)
    (right-child* x))

  (defun first-child-ref:string (x:object{node-sch})
    (bind x {'right-child:=r, 'left-child:=l}
      (if (!= l NIL) l r)))

  (defun is-left-child:bool (x:object{node-sch})
    (= (at 'id x) (at 'left-child (parent x))))

  (defun is-left-child*:bool (x:object{node-sch} p:object{node-sch})
    (= (at 'id x) (at 'left-child p)))

  (defun is-right-child:bool (x:object{node-sch})
    (= (at 'id x) (at 'right-child (parent x))))

  (defun is-right-child*:bool (x:object{node-sch} p:object{node-sch})
    (= (at 'id x) (at 'right-child p)))

  (defun sibling:object{node-sch} (x:object{node-sch})
    (bind (parent x) {'left-child:=l-child, 'right-child:=r-child}
      (get-node (if (= (at 'id x) l-child) r-child l-child))))

  (defun sibling-ref:string (x:object{node-sch} parent:object{node-sch})
    (bind parent {'left-child:=l-child, 'right-child:=r-child}
      (if (= (at 'id x) l-child) r-child l-child)))

  (defun ref-is-red:bool (ref:string)
    (and (!= ref NIL)
         (is-red (get-node ref))))

  (defun ref-is-black:bool (ref:string)
    (or (= ref NIL)
        (is-black (get-node ref))))

  (defun are-children-black:bool (x:object{node-sch})
    (bind x {'right-child:=r, 'left-child:=l}
      (and (ref-is-black r) (ref-is-black l))))

  (defun is-left-child-red:bool (x:object{node-sch})
    (ref-is-red (at 'left-child x)))

  (defun is-right-child-red:bool (x:object{node-sch})
    (ref-is-red (at 'right-child x)))

  (defun is-sibling-red:bool (x:object{node-sch})
    (ref-is-red (sibling-ref x (parent x))))

  (defun is-red:bool (x:object{node-sch})
    (at 'red x))

  (defun is-black:bool (x:object{node-sch})
    (not (at 'red x)))

  (defun is-root:bool (x:object{node-sch})
    (= (at 'parent x) NIL))

  (defun has-right-child:bool (x:object{node-sch})
    (!= NIL (at 'right-child x)))

  (defun has-left-child:bool (x:object{node-sch})
    (!= NIL (at 'left-child x)))

  (defun has-2-children:bool (x:object{node-sch})
    (bind x {'right-child:=r, 'left-child:=l}
      (and (!= r NIL) (!= l NIL))))

  (defun has-no-children:bool (x:object{node-sch})
    (bind x {'right-child:=r, 'left-child:=l}
      (and (= r NIL) (= l NIL))))

  (defun find-insert-position:object{node-sch} (key:decimal node:object{node-sch} _:integer)
    (if (< key (at 'key node))
        (left-child* node)
        (right-child* node)))

  ; ------------------- WRITE UTIL FUNCTIONS -----------------------------------
  ; ----------------------------------------------------------------------------
  (defun make-node:object{node-sch} (tree:string parent:object{node-sch} id:string key:decimal left-right:bool)
    (require-capability (WRITE-TREE))
    (enforce (if left-right (not? (has-left-child) parent) (not? (has-right-child) parent)) "Bad insert position")

    (let ((node:object{node-sch} {'id:id, 'key:key, 'red:true, 't:tree,
                                  'parent:(at 'id parent), 'left-child:NIL, 'right-child:NIL}))
      (insert nodes id node)
      (if left-right
          (update nodes (at 'id parent) {'left-child:id})
          (update nodes (at 'id parent) {'right-child:id}))
      node)
  )

  (defun update-root:string (tree:string ref:string)
    (require-capability (WRITE-TREE))
    (update trees tree {'root:ref}))

  (defun make-root:bool (tree:string id:string key:decimal)
    (require-capability (WRITE-TREE))
      (insert nodes id {'id:id, 'key:key, 'red:false, 't:tree,
                        'parent:NIL, 'left-child:NIL, 'right-child:NIL })
      (update-root tree id)
    true
  )

  (defun recolor:object{node-sch} (x:object{node-sch})
    (require-capability (WRITE-TREE))
    (bind x {'red:=color, 'id:=id}
      (update nodes id {'red:(not color)})
      (+ {'red:(not color)} x))
  )

  (defun exchange-color:object{node-sch} (x:object{node-sch} y:object{node-sch})
    (require-capability (WRITE-TREE))
    (bind x {'red:=color-x, 'id:=id-x}
      (bind y {'red:=color-y, 'id:=id-y}
        (update nodes id-x {'red:color-y})
        (update nodes id-y {'red:color-x})
      x))
  )

  (defun update-parent:bool (n:object{node-sch} new-ref:string)
    (require-capability (WRITE-TREE))
    (if (is-root n)
        (update-root (at 't n) new-ref)
        (if (is-left-child n)
            (update nodes (at 'parent n) {'left-child:new-ref})
            (update nodes (at 'parent n) {'right-child:new-ref})))
    true
  )

  (defun rotate-right:object{node-sch} (n:object{node-sch})
    (require-capability (WRITE-TREE))
    (bind n {'t:=tree, 'id:=n-id, 'parent:=n-parent }
      (bind (left-child n) {'id:=l-id, 'right-child:=Y }
        ; Update parent or fix root
        (update-parent n l-id)
        ; Invert both nodes
        (update nodes l-id {'right-child:n-id, 'parent:n-parent})
        (update nodes n-id {'left-child:Y, 'parent:l-id})
        ;Fix the child
        (if (!= Y NIL)
            (update nodes Y {'parent:n-id})
            "")
        (+ {'left-child:Y, 'parent:l-id} n)))
  )

  (defun rotate-left:object{node-sch} (n:object{node-sch})
    (require-capability (WRITE-TREE))
    (bind n {'id:=n-id, 'parent:=n-parent}
      (bind (right-child n) {'id:=r-id, 'left-child:=Y }
        ; Update parent or fix root
        (update-parent n r-id)
        ; Invert both nodes
        (update nodes r-id {'left-child:n-id, 'parent:n-parent})
        (update nodes n-id {'right-child:Y, 'parent:r-id})
        ;Fix the child
        (if (!= Y NIL)
            (update nodes Y {'parent:n-id})
            "")
        (+ {'right-child:Y, 'parent:r-id} n)))
  )

  (defun rotate:object{node-sch} (direction:bool n:object{node-sch})
    (if direction (rotate-left n) (rotate-right n)))

  ; ------------------- INSERTION FIX FUNCTIONS --------------------------------
  ; ----------------------------------------------------------------------------
  (defun fix-red-I2:object{node-sch} (p:object{node-sch})
    (recolor p) ; Recolor the parent
    (recolor (sibling p)) ; Recolor the uncle
    (recolor (parent p))) ; Recolor the grandparent

  (defun fix-red-I4:object{node-sch} (p:object{node-sch})
    (recolor p)
    NIL-NODE)

  (defun fix-red-I5:object{node-sch} (p:object{node-sch})
    (rotate (is-left-child p) p))

  (defun fix-red-I6:object{node-sch} (p:object{node-sch})
    (recolor p)
    (let ((gp (parent p)))
      (recolor (rotate (is-right-child* p gp) gp)))
    NIL-NODE)

  (defun --fix-red-violation:object{node-sch} (n:object{node-sch} _:integer)
    (if (is-root n)
        n; Case I3
        (let ((parent (parent n)))
          (if (is-black parent)
              NIL-NODE ; Case I1
              (if (is-root parent)
                  (fix-red-I4 parent) ; Case I4
                  (if (is-sibling-red parent) ; Is uncle red
                      (fix-red-I2 parent) ;Case I2
                      (if (!= (is-left-child* n parent) (is-left-child parent))
                          (fix-red-I5 parent)
                          (fix-red-I6 parent)))))))
  )

  (defun fix-red-violation:bool (n:object{node-sch})
    (let ((last-iter (fold (--fix-red-violation) n ENUM-HALF-DEPTH)))
      (enforce (is-root last-iter) "RB violation"))
  )

  ; ------------------- DELETION FIX FUNCTIONS ---------------------------------
  ; ----------------------------------------------------------------------------
  (defun fix-black-D2:object{node-sch} (n:object{node-sch} p:object{node-sch} s:object{node-sch})
    (recolor s)
    p)

  (defun fix-black-D3:object{node-sch} (n:object{node-sch} p:object{node-sch} s:object{node-sch})
    (rotate (is-left-child* n p) p)
    (recolor p)
    (recolor s)
    n)

  (defun fix-black-D4:object{node-sch} (n:object{node-sch} p:object{node-sch} s:object{node-sch})
    (recolor p)
    (recolor s))

  (defun fix-black-D5:object{node-sch} (n:object{node-sch} p:object{node-sch} s:object{node-sch})
    (rotate (is-right-child* n p) s)
    (recolor (if (is-right-child* n p) (right-child s ) (left-child s))) ; Recolor the close nephew
    (recolor s)
    n)

  (defun fix-black-D6:object{node-sch} (n:object{node-sch} p:object{node-sch} s:object{node-sch})
    (rotate (is-left-child* n p) p)
    (recolor (if (is-left-child* n p) (right-child s ) (left-child s))) ; Recolor the distant nephew
    (exchange-color p s)
    NIL-NODE)

  (defun --fix-black-violation:object{node-sch} (n:object{node-sch} _:integer)
    (if (or? (is-root) (is-red) n)
        n; Case D1 or removed RED
        (let ((parent (parent n))
              (sibling (sibling n)))
          (if (are-children-black sibling) ; Nephews are black (or NIL)
              (if (is-red parent)
                  (fix-black-D4 n parent sibling) ; Case D4
                  (if (is-red sibling) ; Here parent is black (D2 or D3)
                      (fix-black-D3 n parent sibling) ; Case D3
                      (fix-black-D2 n parent sibling))) ; Case D2
              (if (= (is-left-child* n parent) (is-left-child-red sibling)); (is-right-child-red sibling))  ; Here nephew are bicolor
                  (fix-black-D5 n parent sibling) ; Case D5
                  (fix-black-D6 n parent sibling))))) ; Case D6
  )

  (defun fix-black-violation:bool (n:object{node-sch})
    (let ((last-iter (fold (--fix-black-violation) n ENUM-HALF-DEPTH)))
      (enforce (or? (is-root) (is-red) last-iter) "RB violation"))
  )

  (defun find-successor:object{node-sch} (node:object{node-sch})
    (fold (left-child**) (right-child node) ENUM-DEPTH))

  (defun swap-with-successor:object{node-sch} (node:object{node-sch})
    (if (has-2-children node)
        (bind node {'id:=id, 't:=tree, 'parent:=p, 'left-child:=lc, 'right-child:=rc, 'red:=red}
          (bind (find-successor node) {'id:=s-id, 'parent:=s-p, 'right-child:=s-rc, 'red:=s-red}
            (require-capability (WRITE-TREE))
            (update-parent node s-id)
            (if (!= s-id rc)
                (update nodes s-p {'left-child:id})
                 "")
            (update nodes lc {'parent:s-id})
            (if (!= s-id rc)
                (update nodes rc {'parent:s-id})
                "")
            (update nodes s-id {'parent:p, 'left-child:lc, 'right-child:(if (!= s-id rc) rc id), 'red:red})
            (+ {'parent:(if (!= s-id rc) s-p s-id), 'left-child:NIL, 'right-child:s-rc, 'red:s-red} node)))
        node)
  )

  (defun replace-by-child (node:object{node-sch})
    (require-capability (WRITE-TREE))
    (let ((c (first-child-ref node)))
      (if (!= c NIL)
          (update nodes c {'parent:(at 'parent node), 'red:false})
          "")
      (update-parent node c))
  )

  ; ----------------------- PUBLIC FUNCTIONS -----------------------------------
  ; ----------------------------------------------------------------------------
  (defun init-tree:bool (tree:string write-guard:guard default-key:decimal)
    @doc "Initialize a tree"
    (with-capability (INIT-TREE)
      (insert trees tree {'root:NIL, 'write-guard:write-guard})
      (make-root tree (hash tree) default-key))
  )

  (defun delete-node:bool (node:object{node-sch})
    @doc "Delete a node"
    ; Get the node to replace and eventually swap it with a leaf
    (with-capability (INSERT-DELETE)
      (with-read trees (at 't node) {'write-guard:=g}
        (enforce-guard g))
      (let ((node (swap-with-successor node)))
        (if (has-no-children node)
            (fix-black-violation node)
            true)
        (replace-by-child node))
      true)
  )

  (defun delete-value:bool (id:string)
    @doc "Delete a value (ID)"
    (delete-node (get-node id))
  )

  (defun insert-value:bool (tree:string id:string key:decimal)
    @doc "Insert a new value into the tree, with a given id and ordering key"
    (with-capability (INSERT-DELETE)
      (with-read trees tree {'write-guard:=g}
        (enforce-guard g))
      (enforce (!= id NIL) "Try to insert NIL value")
      (let* ((parent (fold (find-insert-position key) (get-root tree) ENUM-DEPTH))
            (new-node (make-node tree parent id key (<= key (at 'key parent)))))
        (fix-red-violation new-node))
      true)
  )

  (defun first-node:object{node-sch} (tree:string)
    @doc "Returns the first node of the tree"
    (fold (left-child**) (get-root tree) ENUM-DEPTH))

  (defun first-value:string (tree:string)
    @doc "Returns the first value of the tree"
    (at 'id (first-node tree)))

  (defun last-node:object{node-sch} (tree:string)
    @doc "Returns the last node of the tree  => Problably the INIT node"
    (fold (right-child**) (get-root tree) ENUM-DEPTH))

  (defun last-value:string (tree:string)
    @doc "Returns the last value of the tree => Problably be the INIT node"
    (at 'id (last-node tree)))

  (defun next-node:object{node-sch} (node:object{node-sch})
    @doc "Returns the next node (iteration)"
    (if (has-right-child node)
        (fold (left-child**) (right-child node) ENUM-DEPTH)
        (parent (fold (lambda (x _:integer) (if (is-left-child x) x (parent x))) node ENUM-DEPTH)))
  )

  (defun prev-node:object{node-sch} (node:object{node-sch})
    @doc "Returns the previous node (iteration)"
    (if (has-left-child node)
        (fold (right-child**) (left-child node) ENUM-DEPTH)
        (parent (fold (lambda (x _:integer) (if (is-right-child x) x (parent x))) node ENUM-DEPTH)))
  )

  (defun dump-tree (tree:string)
    @doc "Mainly a debug function => will return all nodes (including deleted ones) of a tree"
    (with-read trees tree {'root:=r}
      {'root:r, 'tree:(select nodes (where 't (= tree)))})
  )

)
