## mpv-oled-screensaver

Due to  burn-in problems on OLED TVs i decided to script a screensaver for mpv.
After 15 seconds when paused it just fades-in a black screen.

The screensaver can be manually started by binding a key to the appropriate 
predefined script bindings `start_screensaver` or `pause_and_start_screensaver`.
While the former only starts the screensaver when already paused and in 
fullscreen, the latter automatically and additionally sets mpv to pause and 
fullscreen. Both script bindings can be bound in your `input.conf` file with:
```
<new bind> script-binding start_screensaver
<new bind> script-binding pause_and_start_screensaver
```


## Options

#### startAfter
Time after screensaver is shown in seconds (Default: 10s).

#### screensaverColor
Colour of the screensaver in ASS hex BBGGRR (Default: "000000").

#### rainbow
Instead of using one colour, use a rainbow colour transition (Default: false).

#### rainbowStep
How many colour steps per period (Default: 1).

#### rainbowRedrawPrediod
Time between redraws of the rainbow in seconds (Default: 0.03).

#### alphaStep
How many steps for the fade-in of the screensaver (Default: 12).

#### luminance
The Luminace of the rainbow colours (Default: 255).

#### mouseMovementClears
If false only toggling pause, toggling fullscreen, or seeking clears the screensaver.
If true also moving the mouse clears the screensaver. (Default: true)
