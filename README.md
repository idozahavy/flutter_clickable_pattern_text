# Clickable Pattern Text

Clickable pattern text widget that gets pattern and convert the regex patterns into different styles texts inside of RichText widget, and adds an onClick function to them.

## Examples

The most obvious use of it can be to change a bunch of text that contains urls to clickable urls that opens them in the launch method (with url_launcher dependency)

```
...
ClickablePatternText(
	'my email is a@b.com you can click it or this a@c.com ',
	style: TextStyle(color: Colors.black, fontSize: 16),
	clickableDefaultStyle: TextStyle(
		color: Colors.blue, decoration: TextDecoration.underline),
	patterns: [
		ClickablePattern(
			name: 'url',
			pattern: myUrlRegex,
			onClicked: (url, clickablePattern) => launch(url),
			// style: TextStyle(
			//	color: Colors.blue, decoration: TextDecoration.underline)
		),
	],
),
...
```

you can choose a default clickable style or a pattern specific style for the text.

Another obvious use is for phone numbers again with the launch method

```
...
ClickablePatternText(
	'my phone is 123456789 or 987654321, my friends phone is:456321987 ',
	style: TextStyle(color: Colors.black, fontSize: 16),
	// clickableDefaultStyle: TextStyle(
	//	color: Colors.blue, decoration: TextDecoration.underline),
	patterns: [
		ClickablePattern(
			name: 'phone',
			pattern: myPhoneRegex, // r'(?<=[ ,.:]|^)\d{9}(?=[ ,.]|$)'
			onClicked: (phone, clickablePattern) => launch(phone),
			style: TextStyle(
				color: Colors.blue, decoration: TextDecoration.underline)
		),
	],
),
...
```

## Defaults

Currently there are two default patterns in ClickablePatternText.patternDefaults and those are:
1. email_1 : simple email regex that the click does nothing.
2. phone_1 : simple 10 digit phone number that does nothing.

### Notes

If you find any problem or something you want to improve (even if you don't know how to code it), you can open issues on github, I will be grateful.