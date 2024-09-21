# Introduction
Welcome to the Bedlam Theatre Scavenger Hunt scoring website.

# Setup
## System Dependencies
1) Install Ruby (see gemfile for version)
2) Install Node.js/Yarn (most recent probably fine)
3) Install MySQL.

## Instructions
1) Create a database user with the username `scav_hunt` and an empty password who has access to all schemas matching the pattern `scav\_hunt\_%`. You can set the access restriction to `localhost` for extra security. 
2) Clone the repository
3) Copy the master.key file to your local repository. Ask someone who already has it for a copy.
4) Run `bundle install`
5) Run `yarn install`
6) Run `rails db:setup`

# Development
## Running the website
1) Run `rails s` and check if the website loads at `localhost:3000`
2) You might need to run `yarn build` and `yarn build:css` if changes you make do not automatically reload.

# Testing
1) Run `rails test -d`. You can use `rails test -h` for more details, for example, how to run a specific test file only.
2) You can view test coverage by opening `coverage/index.html` using a browser of your choice.

# Deployment
TBD