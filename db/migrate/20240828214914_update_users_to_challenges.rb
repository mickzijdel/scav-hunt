class UpdateUsersToChallenges < ActiveRecord::Migration[7.2]
  def change
    remove_column :challenges, :name, :string
    remove_column :challenges, :password, :string
    remove_column :challenges, :is_admin, :boolean
    remove_column  :challenges, :team_id, :integer

    add_column :challenges, :number, :integer
    add_column :challenges, :description, :string
    add_column :challenges, :points, :integer

  end
end
