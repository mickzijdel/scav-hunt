# Challenge#number and User#name are both validated for uniqueness in the model and
# enforced by nothing at all in the database. A model uniqueness validation is a
# SELECT followed by an INSERT, so two requests that interleave between the two both
# pass -- which is exactly the shape of the CSV import, where two organisers
# uploading the same sheet at once can each create the same challenge number.
#
# MySQL builds these online (ALGORITHM=INPLACE, LOCK=NONE) and both tables are small
# -- tens of challenges, tens of teams -- so no concurrent-index dance is needed.
class AddUniqueIndexesForValidatedUniqueness < ActiveRecord::Migration[8.1]
  def up
    # Fail before touching anything, with the offending values named, rather than
    # letting MySQL abort on the first duplicate it happens to meet. Neither column
    # can be de-duplicated automatically: a challenge number and a team name are
    # both meaningful to humans, so a person has to decide which one changes.
    ensure_no_duplicates!(:challenges, :number)
    ensure_no_duplicates!(:users, :name)

    add_index :challenges, :number, unique: true, if_not_exists: true
    add_index :users, :name, unique: true, if_not_exists: true
  end

  def down
    remove_index :challenges, column: :number, if_exists: true
    remove_index :users, column: :name, if_exists: true
  end

  private

  def ensure_no_duplicates!(table, column)
    quoted_column = connection.quote_column_name(column)

    duplicates = connection.select_values(<<~SQL.squish)
      SELECT #{quoted_column}
      FROM #{connection.quote_table_name(table)}
      GROUP BY #{quoted_column}
      HAVING COUNT(*) > 1
    SQL

    return if duplicates.empty?

    raise ActiveRecord::MigrationError,
          "Cannot add a unique index on #{table}.#{column}: these values appear more than once " \
          "-- #{duplicates.join(', ')}. Resolve the duplicates, then run this migration again."
  end
end
