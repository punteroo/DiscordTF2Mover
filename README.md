# | Discord - TF2 | Voice Channel Mover
Moves users on Discord to their respective team voice channels, useful for private pugs. You can set your **default** voice channel where all the users sit and talk before the pug starts, then after all teams are formed In-Game, with a simple server command all the users inside the default channel will be moved to their respective **team** voice channels.

It is mildly customizable with ConVars that control the plugin's connection and behaivour.

**As this is the initial release, I'm planning on adding much more customization and easier installation for a more drag & drop install. Please, don't hesitate to recommend what could be done better by making an issue on the repo. My top priority with this project is simplify it as much as possible, any tip is welcome.**

# Credits
### The original plugin (**private**) was made by my all-time companion [**ratawar**](https://github.com/ratawar). Most of the idea and logic was provided by him, I just made a more user-friendly version for people to utilize so please thank him more than me for this project's life.


# Dependencies
This plugin makes fair use of **NodeJS**, **Express**, **PHP**, **MySQL**, **Composer** and **SourceMod**. It requires one extension to manage **POST** requests to send the signal over to the Discord bot so a user move is performed, that extension being **[REST in Pawn](https://forums.alliedmods.net/showthread.php?t=298024)** by **[DJ Tsunami](https://github.com/ErikMinekus/)**.

I'll explain in much more detail how to install and set-up the enviroment to get the Discord Bot, API REST and plugin running. As more releases come, I'll make this easier to do so please be patient :)

# Installation

Database
--------
I've included a **.sql** file with the structure of the **MySQL** database needed to utilize the plugin. This database stores the player's **SteamID64** and **Discord ID** respectively for the bot to differ which user In-Game corresponds to which Discord user.

Simply import the **.sql** file to a new database with the name ``dmover`` and you're good to go.

Web Server
----------
The web server's only purpose is to offer users a **linking page**. I'm planning on ditching the Web Server for a simpler linking method with only the **Express** app, but for now I'm using this alternative.

Download any **Apache** distribution with **PHP** and set-up a Web Server with the files I've provided on [the folder **web**](https://github.com/punteroo/DiscordTF2Mover/tree/main/web). Use **Composer** to set up the dependencies for the **[Discord OAuth2 PHP API](https://github.com/Xwilarg/Discord-OAuth2-PHP)** (installation steps w/ Composer on their GitHub page).

This is where users connect and link their accounts. Inside of **index.php** is a variable called **$db**, modify the parameters listed for succesful connection to your database. Ideally, your ``database`` name would be ``dmover``.

```php
// Database connection.
$db = mysqli_connect("hostname", "username", "password", "database");
```

You must also set your respective Discord API App credentials for the **OAuth2** to work properly. If you're confused about what these credentials are consult the [Discord API Docs](https://discord.com/developers/docs/intro).

```php
// CLIENT-ID-HERE: Replace this with the Client ID of the application
// SECRET: Replace this with the Secret of the application
// CALLBACK-URL: Replace this with the redirect URL (URL called after the user is logged in, must be registered in https://discordapp.com/developers/applications/[YourAppId]/oauth)
// Enter your Discord Oauth details here:
$oauth2 = new OAuth2("CLIENT-ID-HERE", "SECRET", "CALLBACK-URL");
```

Once this data is replaced with yours, the Web Server is ready to recieve player linkings.

API REST & Discord Bot
----------------------
The API that recieves data from the plugin to pass on to the bot is an **Express** app. It's only purpose is to grab the **JSON** sent from the server plugin and parse it for the **Discord Bot** to move the users accordingly.

To set up the **API REST** environment, you need to download and install [Node.JS](https://nodejs.org/en/) to your respective server. You will also need Node for the Discord Bot as well.

Inside the [nodejs folder](https://github.com/punteroo/DiscordTF2Mover/tree/main/nodejs) I've left the **Discord Bot** and **Express App** code on the file ``bot.js``. You must edit this file to input database credentials and your Discord Bot token. Just replace your data in here, assuming you're running the Node App in the same network as the Database.

```js
// Adjust all your database connection and API REST settings here.
// These are obligatory to modify.
const settings = {
	apiPort: '201',
	apiName: 'mover',
	botToken: "DISCORD-BOT-TOKEN",
	dbHost: 'hostname',
	dbUser: 'username',
	dbPass: 'password',
	dbName: 'database'
}
```

If you ever change the ``apiName`` value, you'll have to also change this on the plugins' ConVars.

After you've configured everything, just run the file ``bot.js`` using ``node bot.js`` and everything's ready to go.

SourceMod Plugin
----------------
The plugin is simply Drag&Drop to the ``plugins`` folder inside ``sourcemod/plugins/``. There are ConVars which you need to modify before the plugin works as intended (I'm planning on making a **.cfg** file to configure these much more easily). Below I'll leave an explanation of the ConVars:

```
sm_dmover_redchannel "channel-id"           // The Voice Channel ID for the RED team players.
sm_dmover_bluchannel "channel-id"           // The Voice Channel ID for the BLU team players.
sm_dmover_defaultchannel "channel-id"       // The Voice Channel ID where everyone is by default, before the teams are moved.
sm_dmover_guild "discord-server-id"         // The Discord server ID where the bot is.
sm_dmover_cooldown "9.0"                    // Cooldown (in seconds) in-between moving attempts.
sm_dmover_server "http://yourserver.com"    // The Express App server hostname (or IP) where the API REST is.
sm_dmover_server_api "mover"                // The API REST's path name (this has to be the same as settings.apiName set on your Express app.
```

If everything is set-up accordingly, just use the command ``sm_move`` to start moving players.

### Commands

``sm_move [teams | default]`` **- ``teams`` moves all players from the default channel to their respective team channels. ``default`` moves all the players back to the default channel.**
