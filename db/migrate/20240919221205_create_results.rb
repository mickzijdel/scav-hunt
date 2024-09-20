class CreateResults < ActiveRecord::Migration[7.2]
  def change
    create_table :results do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.integer :regular_points, null: false
      t.integer :bonus_points, null: false

      t.timestamps
    end

    add_index :results, [ :user_id, :challenge_id ], unique: true
  end
end
