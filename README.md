# 🌟 Echosight App 🌟

Welcome to the **Echosight App** repository! Dive into the dynamic world of Twitter analytics with our visually stunning and intuitive dashboard. Echosight App aims to provide users with insightful data about their Twitter presence, all within an engaging and aesthetically pleasing interface. 🚀

## Getting Started 🌈

Begin your journey with Echosight App by cloning this repository to your local machine:

```
git clone git@github.com:Virgola-Limited/echosight_app.git
cd echosight_app
```

### Prerequisites 📋

* Ruby (version 3.2.2 or later)
* Node.js (LTS version)
* PostgreSQL (latest version)
* Docker (for containerized environments)
* Foreman or Overmind (for process management)
* Redis: brew install redis

### Installation 💾

Set up your environment by running:

```bash
bin/setup
```

This script will install all necessary dependencies, set up the database, and prepare your development environment.

### Local Development

Developing the Echosight App is streamlined to support various environments, catering to different developer preferences and system setups. You can use Docker for a containerized setup or Foreman/Overmind for a more traditional local environment. The `bin/dev` script is a convenient entry point for starting the application, automatically detecting the best method to use based on your system's configuration.

#### Using `bin/dev` Script:

The `bin/dev` script simplifies the process of starting your development environment. It checks if Docker is available and uses it preferentially; if not, it falls back to using Foreman or Overmind. This approach ensures a seamless setup regardless of your local environment.

To start the development environment:

```bash
./bin/dev
```

> **Note:** Make sure you run `bin/setup` before starting the development environment.

This script will execute the following steps:

1. **Check for Docker**: If Docker and Docker Compose are installed, it will use `docker compose up` to start all services defined in `compose.yml`.
2. **Fallback to Foreman/Overmind**: If Docker is not available, it will use Foreman or Overmind to start the services defined in `Procfile.dev`.

This method ensures that any issues with your development setup are immediately apparent, making troubleshooting more straightforward.

#### Manual Setup:

While `bin/dev` is the recommended way to start your development environment, you can also manually start the services using Docker or Foreman/Overmind.

##### Using Docker:

Run the following command to build and start all services with Docker Compose:

```bash
docker compose up
```

This command starts the Rails server, Mailcatcher, Vite, and the PostgreSQL database within Docker containers, isolating your development environment from your local setup.

##### Using Foreman/Overmind:

If you prefer not to use Docker, you can start the services using Foreman or Overmind:

```bash
foreman start -f Procfile.dev
```

or

```bash
overmind start -f Procfile.dev
```

This method starts the Rails server, Mailcatcher, and Vite directly on your local machine, allowing for a traditional development experience.

### Why Use `bin/dev`?

Using `bin/dev` provides several advantages:

1. **Simplicity**: It offers a single, consistent way to start your development environment, regardless of the underlying method (Docker or Foreman/Overmind).
2. **Flexibility**: It automatically detects the best method to use based on your system's configuration, making it adaptable to different development setups.
3. **Troubleshooting**: If there are issues with your environment setup, using a central script like `bin/dev` makes it easier to identify and resolve these issues.
4. **Documentation**: The script itself acts as documentation, clearly showing the steps taken to start the environment.

By following these instructions, you can easily set up and start working on the Echosight App in a development environment that best suits your preferences and system configuration.

### Features 🌟

* **Twitter Analytics Dashboard**: Get a comprehensive view of your Twitter activity.
* **Follower Growth Charts**: Monitor your follower growth trends.
* **Impression Statistics**: Uncover valuable insights on content performance.
* **Engagement and Conversion Rates**: Understand and enhance audience engagement.
* **Post Analytics**: Analyze individual post metrics in depth.
* **User Authentication**: Secure login with Devise, Omniauth, and Omniauth Twitter.
* **TailwindCSS**: For a modern, utility-first styling approach.
* **Vite Server Integration**: Enhanced frontend tooling environment (integration in progress 🔄).
* **Admin Toolkit**: Manage backend operations efficiently (currently under development 🛠️).

## Directory Structure 📁

Explore the organized structure of our project:

```bash
➜  echosight_app git:(dl/docs) ✗ tree -L 2
.
├── Dockerfile
├── Gemfile
├── Gemfile.lock
├── Procfile
├── Procfile.dev
├── README.md
├── Rakefile
├── app
│   ├── (various directories)
├── bin
│   ├── (various scripts)
├── config
│   ├── (configuration files)
├── db
│   ├── (database files)
├── lib
│   ├── (libraries)
├── log
│   ├── development.log
├── package-lock.json
├── package.json
├── public
│   ├── (public assets)
├── storage
├── tmp
│   ├── (temporary files)
├── vendor
│   └── (vendor files)
└── vite.config.ts
```

## Deployment 🚀

We're currently deploying the Echosight App to Heroku, ensuring a quick and efficient update process.

## Contributing 🤝

Interested in contributing? Great! We don't want you here so please go. 😊

## License 📜

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments 🙏

* Thanks to Mostafizurhimself for the theme of our Admin Toolkit.
* Gratitude to all the contributors and stars on GitHub!
* A big shoutout to the amazing Ruby and Rails community.
