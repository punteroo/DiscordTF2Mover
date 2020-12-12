<?php

require __DIR__ . '/vendor/autoload.php';

use Xwilarg\Discord\OAuth2;

// CLIENT-ID-HERE: Replace this with the Client ID of the application
// SECRET: Replace this with the Secret of the application
// CALLBACK-URL: Replace this with the redirect URL (URL called after the user is logged in, must be registered in https://discordapp.com/developers/applications/[YourAppId]/oauth)
// Enter your Discord Oauth details here:
$oauth2 = new OAuth2("CLIENT-ID-HERE", "SECRET", "CALLBACK-URL");

// Database connection.
// 
$db = mysqli_connect("hostname", "username", "password", "database");

if ($oauth2->isRedirected() === false) { // Did the client already logged in ?
    // The parameters can be a combination of the following: connections, email, identity or guilds
    // More information about it here: https://discordapp.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes
    // The others parameters are not available with this library
    $oauth2->startRedirection(['identify', 'connections']);
} else {
    // We preload the token to see if everything happened without error
    $ok = $oauth2->loadToken();
    if ($ok !== true) {
        // A common error can be to reload the page because the code returned by Discord would still be present in the URL
        // If this happen, isRedirected will return true and we will come here with an invalid code
        // So if there is a problem, we redirect the user to Discord authentification
        $oauth2->startRedirection(['identify', 'connections']);
    } else {
        // ---------- USER INFORMATION
        $answer = $oauth2->getUserInformation(); // Same as $oauth2->getCustomInformation('users/@me')
		
		$discordId = "";
        if (array_key_exists("code", $answer)) {
            exit("An error occured: " . $answer["message"]);
        } else {
			$discordId = $answer['id'];
			
            echo "Hello " . $answer["username"] . "#" . $answer["discriminator"] . "<br>";
        }

        echo '<br/><br/>';
        // ---------- CONNECTIONS INFORMATION
        $answer = $oauth2->getConnectionsInformation();
		
		$steamId = "";
        if (array_key_exists("code", $answer)) {
            exit("An error occured: " . $answer["message"]);
        } else {
            foreach ($answer as $a) {
				if ($a["type"] == "steam")
					$steamId = $a["id"];
            }
        }
		
		if (empty($steamId) || empty($discordId))
			exit("You don't have a Steam account linked to your Discord. Link one to begin the Mover linking process.");
		
		mysqli_query($db, "INSERT INTO dmover_users (steamid, discordid) VALUES ('$steamId', '$discordId')");
		
		echo "Your account has been successfuly linked to our database. You can exit this page now.";
    }
}
?>