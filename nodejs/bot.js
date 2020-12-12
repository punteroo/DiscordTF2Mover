let Express    = require('express');
let Discord    = require('discord.js');
let bodyParser = require('body-parser');
let mysql      = require('mysql');

const app  = Express();
const disc = new Discord.Client();

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

let db = mysql.createConnection({
	host     : settings.dbHost,
	user     : settings.dbUser,
	password : settings.dbPass,
	database : settings.dbName
});

// Login to Discord bot and connect to our database.

disc.login(settings.botToken);

db.connect();

// Set the port and make use of the JSON bodyparser.

app.set('port', settings.apiPort);

app.use(bodyParser.json())

// Begin to listen on the API REST and message console once the bot is on.

app.listen(app.get('port'), () => {
	console.log(`Now listening for JSON data on port ${app.get('port')}...`);
});

disc.on('ready', () => {
	console.log(`Now executing bot as ${disc.user.tag}...`);
});



function IsTeamMove(action) {
	return (action.toLowerCase() == "teams");
}

function findPlayer(array, value) {
    for(var i = 0; i < array.length; i += 1) {
        if(array[i].steamid == value) {
            return i;
        }
    }
    return -1;
}


/////////////
// EXPRESS //
/////////////

app.post(settings.apiName, function (req, res) {
	let json = req.body;
	
	res.status(200);
	
	let bluPlayers = json.blu,
		redPlayers = json.red,
		defChannel = json.channelDef,
		bluChannel = json.channelBlu,
		redChannel = json.channelRed,
		guild      = json.guild,
		action     = json.action;
	
	db.query("SELECT * FROM dmover_users", function (err, res, fields) {
		
		/////////////
		// DISCORD //
		/////////////
		
		bluPlayers.forEach(pId => {
			let index = findPlayer(res, pId);
			
			if (index != -1) {
				let server = disc.guilds.cache.find(g => g.id == guild);
				
				if (server != undefined) {
					let user = server.members.cache.find(u => u.id == res[index].discordid);
					
					if (user != undefined) {
						let toChannel = IsTeamMove(action) ? bluChannel : defChannel;
						
						if (user.voice.channelID != toChannel)
							user.voice.setChannel(toChannel);
					}
				}
			}
		});
	
		redPlayers.forEach(pId => {
			let index = findPlayer(res, pId);
			
			if (index != -1) {
				let server = disc.guilds.cache.find(g => g.id == guild);
				
				if (server != undefined) {
					let user = server.members.cache.find(u => u.id == res[index].discordid);
					
					if (user != undefined) {
						let toChannel = IsTeamMove(action) ? redChannel : defChannel;
						
						if (user.voice.channelID != toChannel)
							user.voice.setChannel(toChannel);
					}
				}
			}
		});
	});
});