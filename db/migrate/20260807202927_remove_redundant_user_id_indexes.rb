# Both of these are the leftmost prefix of a composite unique index on the same
# table -- (user_id, challenge_id) and (user_id, group_id) -- so InnoDB can answer
# everything the single-column index answered from the composite, including the
# index requirement of the user_id foreign key, which only needs *some* index with
# the column leftmost. All they were buying was a second B-tree to keep up to date
# on every write.
#
# Dropping an index is the low-risk direction: nothing depends on it existing, and
# the worst case if this reasoning were wrong is a slower query, recoverable by
# rolling back (this migration is reversible).
class RemoveRedundantUserIdIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :results, column: :user_id, name: "index_results_on_user_id"
    remove_index :group_permissions, column: :user_id, name: "index_group_permissions_on_user_id"
  end
end
