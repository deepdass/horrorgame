## Idea 
A retro horror game with unique visuals thats use shader techanics like Posterization (like [this](https://www.imgonline.com.ua/eng/posterization.php)) and pixelation like seen in the ps1 games and simulating other limitations they had 
<br>possibly a psychological horror game but have to learn about it like what make things scary and by what scares me 
<br>gonna be first person and things of the setting to be a cave (had this idea for a long time) as could be a good setting for psychological horror but not sure how the Posterization effect will work in the setting


# Retro look

Heya this is a guide and my understanding of how you can recreate the aesthetic of the PlayStation 1 era graphics inside Godot, from having limited colors, jitter effect of pixels, lower resolution that gave it the characteristics aesthetic which arose due the techanical limitation of the hardware, but you may ask "why, we got better hardware no" but what the fun in that

## resolution
First lets have the resolution be lower than you are probably use too

ok so first go to Project -> project settings -> display -> window or just search viewport width inside project settings 
<br>Then change the viewport width and height to a lower 4:3 resolution for example
<br>height - 320 or 640
<br>width - 240 or 480
<br>if you want you can go higher that these but you start to lose the pixelation look (640×480 worked the best on my 1080p display)

now if you play the game you will see that the game window is so small to fix that again go to Project -> project settings -> display -> window -> stretch and change the mode to viewport, so what it does is that it upscales the game to your viewport resolution

few other changes we have to make in project settings
<br>1. rendering/textures/canvas_textures/default_texture_filter = nearest ## this changes how the textures are scaled, in our case gives it the pixelation look
<br>2. rendering/shading/overrides/force_vertex_shading = true ## this forces the lighting to be at vertex level rather that the default pixel to pixel which give smooth gradient
<br>and now just save and restart

## Jitter effect
in my opinion this effect characterizes ps1 games the best, the jitter effect
so what is it, its the effect when polygons snap to pixels at the rasterization stage of 3D rendering and give the polygon a jitter effect
<br>why does this happen, The ps1 hardware rasterizer was unable to render polygons at a sub pixel level due to lack of precision to calculate positions between pixels so it only worked with integers and rounder off the decimals, which caused them to appear snapping at lower resolution (if only it could render at higher resolution it would not be that evident), modern gpus can accurately calculate to sub pixel level and can render at higer res 

## Colors
did you know ps1 game only used 32,768 colors or less to todays standard 16,777,216 color or even 281,474,976,710,656 with 16 bit for just rgb values even more with rgba textures for that

Color Math
<br>Number of color possible is represented with bit depth simply-put, bits are contained in pixels and the amount of bits that we can store in a pixel is bitdepth (like 8bit or 16bit) and bit depth is just a exponential function 
<br>8 bit = 2^8 = 256 on one channel, so if there are 3 channels, number of color possible is = 256 × 256 × 256 which is equal to 16,777,216
<br>16 bit = 2^16 = 65,536 on one channel

with increase in number of color, it increase the memory and size needed
<br>i use to think like 32768 is a lot a color no, but I was wrong even with these many color you could see color banding (not a smooth gradent between colors)

### Recreate
Add a canvas layer and a color rect as the child of it and set the anchor to full rect 
<br>then go to the material section and add a new shader material 

#### code
```
shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture, repeat_disable, filter_nearest; ## get what is being rendered, tells Godot to not tile it and use pixel-perfect sampling so it doesnt get blurry

const float dither[16] = float[16]( ## 4×4 Bayer ordered dither matrix, it hold the offset values that gets applied to each pixel depending on its screen postion 
	-4.0,  0.0, -3.0,  1.0,
	 2.0, -2.0,  3.0, -1.0,
	-3.0,  1.0, -4.0,  0.0, 
	 3.0, -1.0,  2.0, -2.0
);


void fragment() { ## fragment func lets you manipulation each pixel 
	vec3 screen_color = texture(screen_tex, UV).rgb; ## get color of the pixel
	
    ## this gets where the pixel sit in the dither matrix
	int x = int(FRAGCOORD.x) % 4; ## FRAGCOORD is the pixel's actual 2D screen postion and % get it to 0 to 3 range 
	int y = int(FRAGCOORD.y) % 4;
	int index = y * 4 + x; ## converts 2D coordinates into a flat array index
	
	float dither_offset = (dither[index] / 8.0); ## gets the offset
	
	vec3 quantized_color = floor((screen_color * 255.0) / 8.0 + dither_offset) /31.0; ## quantizes 8bit color with dither offset to a 5bit color 
    ## (screen_color * 255.0) screen color is in 0 to 1 range * 255 changes it into 0-255 range
    ## (screen_color * 255.0) / 8.0 divides it to have only 32 colors or 5 bit channel
    ## + dither_offset adds noise more on this later
    ## floor() snaps it to nearest no
    ## /31.0 as the color cannot be in 0 to 31 range so this changes it into 0-1 range 
	
	COLOR = vec4(quantized_color,1); ## applies the color
}
```

