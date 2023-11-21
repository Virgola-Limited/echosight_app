# 🌟 Echosight App 🌟

Welcome to the **Echosight App** repository! Dive into the dynamic world of Twitter analytics with our visually stunning and intuitive dashboard. Echosight App aims to provide users with insightful data about their Twitter presence, all within an engaging and aesthetically pleasing interface. 🚀

## Getting Started 🌈

Begin your journey with Echosight App by cloning this repository to your local machine:

```bash
git clone git@github.com:Virgola-Limited/echosight_app.git
cd echosight_app
```

### Prerequisites 📋

* Ruby
* Node.js
* PostgreSQL
* Docker (for containerized environments)

### Installation 💾

Set up your environment by running:

```bash
bin/setup
```

Kickstart the development server using:

```bash
bin/dev
```

We utilize Foreman (or Obsidian) with a Procfile and Procfile.dev for efficient process management. 🛠️

## Features 🌟

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
