insert into webguiVersion values ('4.6.0','upgrade',unix_timestamp());
insert into international values (716,'WebGUI',1,'Login');
insert into international values (717,'WebGUI',1,'Logout');
delete from international where internationalId=624 and namespace='WebGUI' and languageId=1;
insert into international (internationalId,namespace,languageId,message) values (624, 'WebGUI',1,'WebGUI macros are used to create dynamic content within otherwise static content. For instance, you may wish to show which user is logged in on every page, or you may wish to have a dynamically built menu or crumb trail. \r\n<p>\r\n\r\nMacros always begin with a carat (^) and follow with at least one other character and ended with w semicolon (;). Some macros can be extended/configured by taking the format of ^<i>x</i>("<b>config text</b>");. The following is a description of all the macros in the WebGUI system.\r\n<p>\r\n\r\n<b>^a; or ^a(); - My Account Link</b><br>\r\nA link to your account information. In addition you can change the link text by creating a macro like this <b>^a("Account Info");</b>. \r\n<p>\r\n\r\n<i>Notes:</i> You can also use the special case ^a(linkonly); to return only the URL to the account page and nothing more. Also, the .myAccountLink style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^AdminBar;</b><br>\r\nPlaces the administrative tool bar on the page. This is a required element in the "body" segment of the Style Manager.\r\n<p>\r\n\r\n<b>^AdminText();</b><br>\r\nDisplays a small text message to a user who is in admin mode. Example: ^AdminText("You are in admin mode!");\r\n<p>\r\n\r\n<b>^AdminToggle; or ^AdminToggle();</b><br>\r\nPlaces a link on the page which is only visible to content managers and adminstrators. The link toggles on/off admin mode. You can optionally specify other messages to display like this: ^AdminToggle("Edit On","Edit Off");\r\n<p>\r\n\r\n<b>^C; or ^C(); - Crumb Trail</b><br>\r\nA dynamically generated crumb trail to the current page. You can optionally specify a delimeter to be used between page names by using ^C(::);. The default delimeter is >.\r\n<p>\r\n\r\n<i>Note:</i> The .crumbTrail style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^c; - Company Name</b><br>\r\nThe name of your company specified in the settings by your Administrator.\r\n<p>\r\n\r\n\r\n<b>^D; or ^D(); - Date</b><br>\r\nThe current date and time.\r\n<p>\r\n\r\nYou can configure the date by using date formatting symbols. For instance, if you created a macro like this <b>^D("%c %D, %y");</b> it would output <b>September 26, 2001</b>. The following are the available date formatting symbols:\r\n<p>\r\n\r\n<table><tbody><tr><td>%%</td><td>%</td></tr><tr><td>%y</td><td>4 digit year</td></tr><tr><td>%Y</td><td>2 digit year</td></tr><tr><td>%m</td><td>2 digit month</td></tr><tr><td>%M</td><td>variable digit month</td></tr><tr><td>%c</td><td>month name</td></tr><tr><td>%d</td><td>2 digit day of month</td></tr><tr><td>%D</td><td>variable digit day of month</td></tr><tr><td>%w</td><td>day of week name</td></tr><tr><td>%h</td><td>2 digit base 12 hour</td></tr><tr><td>%H</td><td>variable digit base 12 hour</td></tr><tr><td>%j</td><td>2 digit base 24 hour</td></tr><tr><td>%J</td><td>variable digit base 24 hour</td></tr><tr><td>%p</td><td>lower case am/pm</td></tr><tr><td>%P</td><td>upper case AM/PM</td></tr><tr><td>%z</td><td>user preference date format</td></tr><tr><td>%Z</td><td>user preference time format</td></tr></tbody></table>\r\n<p>\r\n\r\n\r\n<b>^e; - Company Email Address</b><br>\r\nThe email address for your company specified in the settings by your Administrator.\r\n<p>\r\n\r\n<b>^Env()</b><br>\r\nCan be used to display a web server environment variable on a page. The environment variables available on each server are different, but you can find out which ones your web server has by going to: http://www.yourwebguisite.com/env.pl\r\n<p>\r\n\r\nThe macro should be specified like this ^Env("REMOTE_ADDR");\r\n<p>\r\n\r\n<b>^Execute();</b><br>\r\nAllows a content manager or administrator to execute an external program. Takes the format of <b>^Execute("/this/file.sh");</b>.\r\n<p>\r\n\r\n\r\n<b>^Extras;</b><br>\r\nReturns the path to the WebGUI "extras" folder, which contains things like WebGUI icons.\r\n<p>\r\n\r\n\r\n<b>^FlexMenu;</b><br>\r\nThis menu macro creates a top-level menu that expands as the user selects each menu item.\r\n<p>\r\n\r\n<b>^FormParam();</b><br>\r\nThis macro is mainly used in generating dynamic queries in SQL Reports. Using this macro you can pull the value of any form field simply by specifing the name of the form field, like this: ^FormParam("phoneNumber");\r\n<p>\r\n\r\n<b>^GroupText();</b><br>\r\nDisplays a small text message to the user if they belong to the specified group. Example: ^GroupText("Visitors","You need an account to do anything cool on this site!");\r\n<p>\r\n\r\n\r\n<b>^H; or ^H(); - Home Link</b><br>\r\nA link to the home page of this site.  In addition you can change the link text by creating a macro like this <b>^H("Go Home");</b>.\r\n<p>\r\n\r\n<i>Notes:</i> You can also use the special case ^H(linkonly); to return only the URL to the home page and nothing more. Also, the .homeLink style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^I(); - Image Manager Image with Tag</b><br>\r\nThis macro returns an image tag with the parameters for an image defined in the image manager. Specify the name of the image using a tag like this <b>^I("imageName")</b>;.\r\n<p>\r\n\r\n<b>^i(); - Image Manager Image Path</b><br>\r\nThis macro returns the path of an image uploaded using the Image Manager. Specify the name of the image using a tag like this <b>^i("imageName");</b>.\r\n<p>\r\n\r\n<b>^Include();</b><br>\r\nAllows a content manager or administrator to include a file from the local filesystem. Takes the format of <b>^Include("/this/file.html")</b>;\r\n<p>\r\n\r\n<b>^L; or ^L(); - Login</b><br>\r\nA small login form. You can also configure this macro. You can set the width of the login box like this ^L(20);. You can also set the message displayed after the user is logged in like this ^L(20,Hi ^a(^@;);. Click %here% if you wanna log out!)\r\n<p>\r\n\r\n<i>Note:</i> The .loginBox style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^LoginToggle; or ^LoginToggle();</b><br>\r\nDisplays a "Login" or "Logout" message depending upon whether the user is logged in or not. You can optionally specify other messages like this: ^LoginToggle("Click here to log in.","Click here to log out.");\r\n<p>\r\n\r\n<b>^M; or ^M(); - Current Menu (Vertical)</b><br>\r\nA vertical menu containing the sub-pages at the current level. In addition, you may configure this macro by specifying how many levels deep the menu should go. By default it will show only the first level. To go three levels deep create a macro like this <b>^M(3);</b>. If you set the macro to "0" it will track the entire site tree.\r\n<p>\r\n\r\n<b>^m; - Current Menu (Horizontal)</b><br>\r\nA horizontal menu containing the sub-pages at the current level. You can optionally specify a delimeter to be used between page names by using ^m(:--:);. The default delimeter is �.\r\n<p>\r\n\r\n<b>^P; or ^P(); - Previous Menu (Vertical)</b><br>\r\nA vertical menu containing the sub-pages at the previous level. In addition, you may configure this macro by specifying how many levels deep the menu should go. By default it will show only the first level. To go three levels deep create a macro like this <b>^P(3);</b>. If you set the macro to "0" it will track the entire site tree.\r\n<p>\r\n\r\n<b>^p; - Previous Menu (Horizontal)</b><br>\r\nA horizontal menu containing the sub-pages at the previous level. You can optionally specify a delimeter to be used between page names by using ^p(:--:);. The default delimeter is �.\r\n<p>\r\n\r\n<b>^Page();</b><br>\r\nThis can be used to retrieve information about the current page. For instance it could be used to get the page URL like this ^Page("urlizedTitle"); or to get the menu title like this ^Page("menuTitle");.\r\n<p>\r\n\r\n<b>^PageTitle;</b><br>\r\nDisplays the title of the current page.\r\n<p>\r\n\r\n<i>Note:</i> If you begin using admin functions or the indepth functions of any wobject, the page title will become a link that will quickly bring you back to the page.\r\n<p>\r\n\r\n<b>^r; or ^r(); - Make Page Printable</b><br>\r\nCreates a link to remove the style from a page to make it printable.  In addition, you can change the link text by creating a macro like this <b>^r("Print Me!");</b>.\r\n<p>\r\n\r\nBy default, when this link is clicked, the current page\'s style is replaced with the "Make Page Printable" style in the Style Manager. However, that can be overridden by specifying the name of another style as the second parameter, like this: ^r("Print!","WebGUI");\r\n<p>\r\n\r\n<i>Notes:</i> You can also use the special case ^r(linkonly); to return only the URL to the make printable page and nothing more. Also, the .makePrintableLink style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^rootmenu; or ^rootmenu(); (Horizontal)</b><br>\r\nCreates a horizontal menu of the various roots on your system (except for the WebGUI system roots). You can optionally specify a menu delimiter like this: ^rootmenu(|);\r\n<p>\r\n\r\n\r\n<b>^RootTitle;</b><br>\r\nReturns the title of the root of the current page. For instance, the main root in WebGUI is the "Home" page. Many advanced sites have many roots and thus need a way to display to the user which root they are in.\r\n<p>\r\n\r\n<b>^S(); - Specific SubMenu (Vertical)</b><br>\r\nThis macro allows you to get the submenu of any page, starting with the page you specified. For instance, you could get the home page submenu by creating a macro that looks like this <b>^S("home",0);</b>. The first value is the urlized title of the page and the second value is the depth you\'d like the menu to go. By default it will show only the first level. To go three levels deep create a macro like this <b>^S("home",3);</b>.\r\n<p>\r\n\r\n\r\n<b>^s(); - Specific SubMenu (Horizontal)</b><br>\r\nThis macro allows you to get the submenu of any page, starting with the page you specified. For instance, you could get the home page submenu by creating a macro that looks like this <b>^s("home");</b>. The value is the urlized title of the page.  You can optionally specify a delimeter to be used between page names by using ^s("home",":--:");. The default delimeter is �.\r\n<p>\r\n\r\n<b>^SQL();</b><br>\r\nA one line SQL report. Sometimes you just need to pull something back from the database quickly. This macro is also useful in extending the SQL Report wobject. It uses the numeric macros (^0; ^1; ^2; etc) to position data and can also use the ^rownum; macro just like the SQL Report wobject. Examples:<p>\r\n ^SQL("select count(*) from users","There are ^0; users on this system.");\r\n<p>\r\n^SQL("select userId,username from users order by username","&lt;a href=\'^/;?op=viewProfile&uid=^0;\'&gt;^1;&lt;/a&gt;&lt;br&gt;");\r\n<p>\r\n\r\n<b>^Synopsis; or ^Synopsis(); Menu</b><br>\r\nThis macro allows you to get the submenu of a page along with the synopsis of each link. You may specify an integer to specify how many levels deep to traverse the page tree.\r\n<p>\r\n\r\n<i>Notes:</i> The .synopsis_sub, .synopsis_summary, and .synopsis_title style sheet classes are tied to this macro.\r\n<p>\r\n\r\n<b>^T; or ^T(); - Top Level Menu (Vertical)</b><br>\r\nA vertical menu containing the main pages of the site (aka the sub-pages from the home page). In addition, you may configure this macro by specifying how many levels deep the menu should go. By default it will show only the first level. To go three levels deep create a macro like this <b>^T(3);</b>. If you set the macro to "0" it will track the entire site tree.\r\n<p>\r\n\r\n<b>^t; - Top Level Menu (Horizontal)</b><br>\r\nA vertical menu containing the main pages of the site (aka the sub-pages from the home page). You can optionally specify a delimeter to be used between page names by using ^t(:--:);. The default delimeter is �.\r\n<p>\r\n\r\n<b>^Thumbnail();</b><br>\r\nReturns the URL of a thumbnail for an image from the image manager. Specify the name of the image like this <b>^Thumbnail("imageName");</b>.\r\n<p>\r\n\r\n<b>^ThumbnailLinker();</b><br>\r\nThis is a good way to create a quick and dirty screenshots page or a simple photo gallery. Simply specify the name of an image in the Image Manager like this: ^ThumbnailLinker("My Grandmother"); and this macro will create a thumnail image with a title under it that links to the full size version of the image.\r\n<p>\r\n\r\n<b>^u; - Company URL</b><br>\r\nThe URL for your company specified in the settings by your Administrator.\r\n<p>\r\n\r\n<b>^URLEncode();</b><br>\r\nThis macro is mainly useful in SQL reports, but it could be useful elsewhere as well. It takes the input of a string and URL Encodes it so that the string can be passed through a URL. It\'s syntax looks like this: ^URLEncode("Is this my string?");\r\n<p>\r\n\r\n\r\n<b>^User();</b><br>\r\nThis macro will allow you to display any information from a user\'s account or profile. For instance, if you wanted to display a user\'s email address you\'d create this macro: ^User("email");\r\n<p>\r\n\r\n<b>^/; - System URL</b><br>\r\nThe URL to the gateway script (example: <i>/index.pl/</i>).\r\n<p>\r\n\r\n<b>^\\; - Page URL</b><br>\r\nThe URL to the current page (example: <i>/index.pl/pagename</i>).\r\n<p>\r\n\r\n<b>^@; - Username</b><br>\r\nThe username of the currently logged in user.\r\n<p>\r\n\r\n<b>^?; - Search</b><br>\r\nAdd a search box to the page. The search box is tied to WebGUI\'s built-in search engine.\r\n<p>\r\n\r\n<i>Note:</i> The .searchBox style sheet class is tied to this macro.\r\n<p>\r\n\r\n<b>^#; - User ID</b><br>\r\nThe user id of the currently logged in user.\r\n<p>\r\n\r\n<b>^*; or ^*(); - Random Number</b><br>\r\nA randomly generated number. This is often used on images (such as banner ads) that you want to ensure do not cache. In addition, you may configure this macro like this <b>^*(100);</b> to create a random number between 0 and 100.\r\n<p>\r\n\r\n<b>^-;,^0;,^1;,^2;,^3;, etc.</b><br>\r\nThese macros are reserved for system/wobject-specific functions as in the SQL Report wobject and the Body in the Style Manager.\r\n<p>\r\n');








