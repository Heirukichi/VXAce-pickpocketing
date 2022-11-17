# VXAce-pickpocketing
_Author: Heirukichi_

## DESCRIPTION
This script adds pickpocketing mechanics to RMVXAce games and allows you to handle pickpocketing result with events.

## TABLE OF CONTENTS
* [Installation](#installation)
* [Usage](#usage)
  * [Compatibility](#compatibility)
* [License](#license)
  * [Important Notice](#important-notice)

## INSTALLATION
Copy the content of HRK_Pickpocketing.rb in your script editor in the game, below Materials.

## USAGE

Once this script is installed in your game, check the Config module in the script itself to configure everything you need. Code is commented with istrcuctions on how to use each parameter.

After doing that, events that shall be pickpocketed MUST have the following line as a script call in the position where you want the pickpocketing to happen.

`start_pickpocketing($game_map.events[@event_id], :normal)`

The `:normal` symbol can be changed with any symbol defined in the script difficulty settings.

Once the pickpocketing ends, a designated switch is turned ON and action result can be checked in a conditional branch selecting the script option and using the following code:
`HRK_PICKPOCKETING::Runtime.last_pickpocketing_result`

In the true branch, you shall put whatever happens in case of success, in the else branch, whatever happens in case of failure.

At the end of the event, the designated switch MUST be set off, otherwise it will not be possible to perform subsequent pickpocketing actions.

### COMPATIBILITY

No compatibility issues with other scripts are known so far.

## LICENSE

This code is under the GNU General Public License v3.0. You can review the complete GNU General Public License v3.0 in the LICENSE file or at this [link](https://www.gnu.org/licenses/gpl-3.0.html).

To sum up things you are free to use this material in any commercial and non commercial project as long as:
- proper credit is given to me (Heirukichi);
- a link to my website is provided (I recommend adding it to a credits.txt file in your project, but any other mean is fine);
- if you modify anything, you still provide credit and properly mark the parts you have modified.

In addition, I would like to be notified if you use this in any project.
You can send me a message containing a link to the finished product using the contact form on my website (check my profile for the link).
The link is not supposed to contain a free copy of the finished product.
The sole purpose of the link is to help me keeping track of where my work is being used.

More information can be found in the script itself.
At the same time, the script contains detailed instructions on how to use it. Read them carefully.

#### *IMPORTANT NOTICE*
If you want to distribute this code, feel free to do it, but provide a link to my website instead of pasting my script somewhere else.
