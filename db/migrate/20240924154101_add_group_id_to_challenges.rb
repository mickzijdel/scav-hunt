class AddGroupIdToChallenges < ActiveRecord::Migration[7.2]
  def change
    add_column :challenges, :group_id, :integer
    add_index :challenges, :group_id
  end
end
