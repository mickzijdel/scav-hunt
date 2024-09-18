# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# TODO: Assign roles

User.create! email: 'admin@bedlamtheatre.co.uk', password: 'Passw0rd', password_confirmation: 'Passw0rd'
User.create! email: 'test@bedlamtheatre.co.uk', password: 'Passw0rd', password_confirmation: 'Passw0rd'
