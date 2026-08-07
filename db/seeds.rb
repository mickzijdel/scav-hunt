# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# bin/docker-entrypoint runs `db:prepare` on every boot, which seeds whenever the
# database is new -- so these seeds run unattended on a fresh deployment. They
# must therefore never create an account whose password is knowable from this
# repository, and must be safe to run twice.

DEFAULT_ACCOUNTS = {
  "admin@bedlamtheatre.co.uk" => { name: "Admin", role: :admin },
  "scorer@bedlamtheatre.co.uk" => { name: "Scorer", role: :scorer },
  "team1@bedlamtheatre.co.uk" => { name: "Team 1", role: :team }
}.freeze

# In development and test a fixed password is convenient and harmless. Anywhere
# else it would be a published credential, so require one to be supplied or
# generate one and print it exactly once, at creation time.
seed_password = ENV["SEED_ADMIN_PASSWORD"].presence ||
                (Rails.env.local? ? "password" : SecureRandom.base58(24))

created_emails = []

DEFAULT_ACCOUNTS.each do |email, attributes|
  User.find_or_create_by!(email: email) do |user|
    user.name = attributes[:name]
    user.role = attributes[:role]
    user.password = seed_password
    user.password_confirmation = seed_password
    created_emails << email
  end
end

if created_emails.any? && ENV["SEED_ADMIN_PASSWORD"].blank? && !Rails.env.local?
  warn <<~NOTICE

    ============================================================
    Seeded #{created_emails.size} account(s) with a generated password:

        #{seed_password}

    This is shown once. Sign in and change it, or set
    SEED_ADMIN_PASSWORD before seeding to choose your own.
    ============================================================

  NOTICE
end

# Settings are admin-editable, so only fill in the ones that do not exist yet --
# never clobber a value someone has already set.
{
  "scoreboard_end_time" => 1.day.from_now.iso8601,
  "scoreboard_visible" => "false",
  # StatisticsService reads this; without it the statistics page used to 500.
  "chart_start_time" => Time.current.iso8601
}.each do |key, value|
  Setting.find_or_create_by!(key: key) { |setting| setting.value = value }
end

Challenge.find_or_create_by!(number: 1) do |challenge|
  challenge.description = "Leave a pineapple in front of someone's door"
  challenge.points = 200
  challenge.group_id = 1
end
