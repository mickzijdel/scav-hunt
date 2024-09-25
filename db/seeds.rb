# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.create! email: 'admin@bedlamtheatre.co.uk', name: 'Admin', password: 'Passw0rd', password_confirmation: 'Passw0rd', role: :admin
User.create! email: 'scorer@bedlamtheatre.co.uk', name: 'Scorer', password: 'Passw0rd', password_confirmation: 'Passw0rd', role: :scorer
User.create! email: 'team1@bedlamtheatre.co.uk', name: 'Team 1', password: 'Passw0rd', password_confirmation: 'Passw0rd', role: :team

Setting.create! key: 'scoreboard_end_time', value: '2024-09-28T14:00:00+01:00'
Setting.create! key: 'scoreboard_visible', value: 'false'
