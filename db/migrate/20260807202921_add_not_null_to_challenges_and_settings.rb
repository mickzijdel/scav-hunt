# Step 2 of 2, after BackfillRequiredChallengeAndSettingColumns has left no NULLs.
# Every one of these columns is already required by a presence validation in the
# model; this is the database agreeing, so a write that goes round Active Record
# (the CSV bulk import, a console fix, a restore) cannot leave the table in a state
# the app believes is impossible.
class AddNotNullToChallengesAndSettings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :challenges, :number, false
    change_column_null :challenges, :description, false
    change_column_null :challenges, :points, false
    change_column_null :challenges, :group_id, false
    change_column_null :settings, :value, false
  end
end
