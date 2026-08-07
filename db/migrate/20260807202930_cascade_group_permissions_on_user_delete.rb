# User has_many :group_permissions, dependent: :delete_all, so Active Record already
# deletes them with the user, without callbacks. The database said RESTRICT, which
# means the two only agree as long as every delete goes through Rails; a console
# `delete`, a bulk cleanup or a restore would hit a foreign key error instead. Say
# the same thing in both places.
#
# Results are deliberately NOT given a cascade: they use dependent: :destroy so that
# Result#ensure_zero_points can still veto deleting a team that has been scored, and
# a database-level cascade would quietly go round that veto.
class CascadeGroupPermissionsOnUserDelete < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :group_permissions, :users
    add_foreign_key :group_permissions, :users, on_delete: :cascade
  end

  def down
    remove_foreign_key :group_permissions, :users
    add_foreign_key :group_permissions, :users
  end
end
