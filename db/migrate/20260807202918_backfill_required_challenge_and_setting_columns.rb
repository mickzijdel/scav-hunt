# Step 1 of 2. The columns below are already nullable on tables that hold live hunt
# data, so the NOT NULL constraints cannot go on until every existing row satisfies
# them -- otherwise the constraint is the thing that discovers the bad row, in the
# middle of a deploy. This migration only moves data; the constraints follow in
# AddNotNullToChallengesAndSettings.
#
# Written against throwaway classes bound to the tables rather than against
# Challenge/Setting: a migration has to keep working after the models have moved on,
# and Setting's presence validation would reject the very rows being repaired.
class BackfillRequiredChallengeAndSettingColumns < ActiveRecord::Migration[8.1]
  class MigrationChallenge < ActiveRecord::Base
    self.table_name = "challenges"
  end

  class MigrationSetting < ActiveRecord::Base
    self.table_name = "settings"
  end

  def up
    backfill_challenge_numbers

    # "" rather than a placeholder: this is what the challenge list already renders
    # for a NULL description, so nothing visible changes.
    fill MigrationChallenge, :description, ""
    fill MigrationChallenge, :points, 0
    # Group 0 is the honest home for a challenge nobody grouped -- it is invisible
    # to every team already, since visibility is granted per group id.
    fill MigrationChallenge, :group_id, 0
    fill MigrationSetting, :value, ""
  end

  def down
    # Intentionally a no-op. Nothing records which rows were filled in, and putting
    # the NULLs back would only re-break the rows this repaired. Rolling the
    # constraint off is AddNotNullToChallengesAndSettings' job.
  end

  private

  def fill(model, column, value)
    model.where(column => nil).in_batches(of: 1_000) { |batch| batch.update_all(column => value) }
  end

  # number is the challenge's identity: the CSV import matches rows on it and a
  # unique index follows in a later migration, so NULLs cannot all be filled with
  # one placeholder. Each gets the next free number above the current maximum,
  # oldest row first.
  def backfill_challenge_numbers
    next_number = (MigrationChallenge.maximum(:number) || 0) + 1

    MigrationChallenge.where(number: nil).order(:id).pluck(:id).each do |id|
      MigrationChallenge.where(id: id).update_all(number: next_number)
      next_number += 1
    end
  end
end
