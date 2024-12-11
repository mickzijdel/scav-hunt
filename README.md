# Introduction
Welcome to the Bedlam Theatre Scavenger Hunt scoring website.

Code by [Mick Zijdel](https://github.com/mickzijdel), styling and specification by [Lewis Eggeling](https://github.com/BasalShark/ )

**IMPORTANT NOTE**: The Rails server is accessible within _the Docker container or in development*_ on port `3000`. However, the server is accessible within _the Docker Host/outside of the Docker container_ on port `2024`.

# Deployment
See the [Bedlam Theatre Wiki](https://wiki.bedlamtheatre.co.uk) for EUTC-specific deployment things.

**I would strongly advise first deploying it to Docker locally before deploying**. You will not be able to access the locally-deployed website once it is up because of SSL certificates, but at least you can check for issues in the deploy process.

## Deploying
The deploy steps (first-time only) are:  
1) Clone this repository.
2) Navigate into the repository.
3) Add a `.env` file with the contents below.
4) Run `sudo docker compose -f docker-compose.yml up -d`  
    a) This will create new containers and start them detached so it will still run when you log out.
5) Setup your Nginx configuration file using the options below.  
    a) If you're not using Nginx (or an alternative) as a reverse proxy, everything should just work if you connect to port `2024` (you can change this port in the `docker-compose.yml` file, for example to the default http port `80` or https port `443`). This is untested though. Feel free to let Mick know and he might be able to help, but it's probably easiest if you just run Nginx as a reverse proxy.
7) That's it! You can check if the containers are running using `sudo docker ps`

Tip: If the `docker compose` fails because of a bundle issue, you can unfreeze the bundle by adding the line `RUN bundle config set frozen false` just before `RUN GIT_EXECUTABLE=/usr/bin/git bundle install` in the Dockerfile. This is not best practice because your packages might not match those in development, but sometimes there are minor inconsistencies when developing on Windows and deploying on Linux.

## Upgrading
To upgrade:
1) Navigate into the repository
2) Pull the updates from the repo from source using `git pull`
3) Run `sudo docker compose down` to stop the current stack/containers.  
4) Run `sudo docker compose -f docker-compose.yml up -d`  
    a) You might need to add the `--build rails` or `--force-recreate` options when upgrading.

If you run into any issues here, please check the deploy instructions above.

## Environment Variables
Ensure that the environment variables are specified in Portainer or in an `.env` file as follows:
```
RAILS_MASTER_KEY=<the master key>
DATABASE_NAME=scav_hunt_production
DATABASE_PASSWORD=<Anything you want>
HOST_URL=<host website, like scavhunt.bedlamtheatre.co.uk. Do not include the scheme. You only need to include the port if you need to specify it when connecting to the website in the browser>
```

## Websockets / ActionCable setup
In production, this website uses Redis as an [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) backend. The main consequences are
1) The `action_cable.allowed_request_origins` config needs to be set in `production.rb`, which is done based on the `HOST_URL` env variable.
2) You need to add a location to your Nginx config file within the server for the scav-hunt website. See the sample Nginx config below.

## Nginx Config
Add this server to your Nginx config file. You might need to change the domain and SSL certificate locations.

```
# New server block for scavhunt.bedlamtheatre.co.uk
server { listen 443 ssl; server_name scavhunt.bedlamtheatre.co.uk;
    ssl_certificate /opt/nginx/certs/bedlamtheatre.co.uk.pem;
    ssl_certificate_key /opt/nginx/certs/bedlamtheatre.co.uk.key;

    location / {
        proxy_pass http://127.0.0.1:2024;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Need to explicitly define the /cable location (the upgrade part is the essential part) for websockets to work.
    location /cable {
        proxy_pass http://127.0.0.1:2024;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
}

```

## Useful Docker commands
- `docker ps`, for a list of all containers and their IDs 
- `docker logs <container_id> --tail 100`, to view the logs
- `docker exec <container_id> <command>`, to run an arbitrary command within the container
- `docker exec -it <container_id> /bin/bash`, to run an interactive shell in a container (keep in mind Docker containers are very slim and don't even have nano)

# Development
## System Dependencies
1) Install Ruby (see gemfile for version)
2) Install Node.js/Yarn (most recent probably fine. I used Node 22)
3) Install MySQL server

## Setup Instructions
1) Create a MySQL database user with the username `scav_hunt` and an empty password who has access to all schemas matching the pattern `scav\_hunt\_%`, or just all schemas using `%`. You can set the access restriction to `localhost` for extra security. 
2) Clone this repository
3) Copy the `master.key` file to your local repository. Ask someone who already has it for a copy.
4) Run `bundle install`
5) Run `yarn install`
6) Run `rails db:setup`

## Running the website
1) Run `rails s` and check if the website loads at `localhost:3000`
2) You might need to run `yarn build` and `yarn build:css` if changes you make do not automatically reload.

# Testing
1) Run `rails test:all -d`. You can use `rails test -h` for more details, for example, how to run a specific test file only.
2) You can view test coverage by opening `coverage/index.html` using a browser of your choice.
