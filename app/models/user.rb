class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, uniqueness: true
  validates :email, :encrypted_password, :role, presence: true

  enum role: {
     team: 0,
     scorer: 1,
     admin: 2
  }
end
