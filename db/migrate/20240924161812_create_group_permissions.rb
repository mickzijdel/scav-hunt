class CreateGroupPermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :group_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :group_id, null: false

      t.timestamps
    end

    add_index :group_permissions, [ :user_id, :group_id ], unique: true
  end
end
