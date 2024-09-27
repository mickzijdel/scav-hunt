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
Currently it is deployed on the EUSA VM using Docker, with the nginx file used to route incoming traffic for scavhunt.bedlamtheatre.co.uk to port 2024, which is the port that Docker has exposed the server on.

## Upgrading
If you want to upgrade, that means you have to `sudo docker compose down` the current image to stop it, and follow the deploy steps.

## Deploying
The deploy steps are:
1) Clone this repository
2) Navigate into the repository
3) Add a `.env` file with the contents below.
4) Run `sudo docker compose -f docker-compose.yml up -d` (this will create new containers and start them detached so it will still run when you log out. You might need to add the `--build rails` or `--force-recreate` options when upgrading)
5) That's it! You can check if it is running using `sudo docker ps`

## Environment Variables
Ensure that the environment variables are specified in Portainer or in an `.env` file as follows:
```
RAILS_MASTER_KEY=<the master key>
DATABASE_NAME=scav_hunt_production
DATABASE_PASSWORD=<Anything you want>
HOST_URL=<host website, like scavhunt.bedlamtheatre.co.uk>
```