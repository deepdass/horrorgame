# RetroHorror
## Idea 
A retro horror game with unique visuals similar to ps1 games and simulating other limitations they had
<br>and experimented with a different prespective and controls inspired by original Resident Evil and Silent Hill games

https://github.com/user-attachments/assets/2394da48-69ad-43c9-8a89-f261b77b139c

# Retro look (Guide)
Heya, this is a guide and my understanding of how you can recreate the aesthetic of the PlayStation 1 era graphics inside Godot, from having limited colors, jitter effect of pixels, lower resolution that gave it the characteristics aesthetic which arose due the technical limitations of the hardware, but you may ask "why, we got better hardware no" but what the fun in that

## Resolution
First lets have the resolution be lower than you are probably use to

Ok, so first go to Project -> Project Settings -> Display -> Window or just search viewport width inside project settings 
<br>Then change the viewport width and height to a lower 4:3 resolution for example
<br>height - 320 or 640
<br>width - 240 or 480
<br>If you want you can go higher that these, but you start to lose the pixelation look (640×480 worked the best on my 1080p display)

Now if you play the game, you will see that the game window is so small. to fix that, 
<br>Again go to Project -> Project settings -> Display -> Window -> Stretch and change the mode to viewport, so what it does is that it upscales the game to your viewport resolution

few other changes we have to make in project settings
<br>1. rendering/textures/canvas_textures/default_texture_filter = nearest ## this changes how the textures are scaled, in our case gives it the pixelation look
<br>2. rendering/shading/overrides/force_vertex_shading = true ## this forces the lighting to be at vertex level rather that the default pixel to pixel which give smooth gradient and we don't want that. 

![vertex_shading](https://github.com/user-attachments/assets/14ddb1b6-2233-4e05-97b4-b9dc099cd12e)

exmaple of vertex shading. Right one is pixel shading and left one is vertex shading
<br>and now just save and restart

## Colors
did you know ps1 game only used 32,768 colors or less to todays standard 16,777,216 color or even 281,474,976,710,656 with 16 bit for just rgb values even more with rgba textures for that

#### Color Math
Number of color possible is represented with bit depth simply-put, bits are contained in pixels and the amount of bits that we can store in a pixel is bitdepth (like 8bit or 16bit) and bit depth is just a exponential function 
<br>8 bit = 2^8 = 256 on one channel, so if there are 3 channels, number of color possible is = 256 × 256 × 256 which is equal to 16,777,216
<br>16 bit = 2^16 = 65,536 on one channel

with increase in number of color, it increase the memory and size needed

### Recreate
Add a canvas layer and a color rect as the child of it and set the anchor to full rect 
<br>then go to the material section and add a new shader material 

#### code
```
shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture, repeat_disable, filter_nearest; // get what is being rendered, tells Godot to not tile it and use pixel-perfect sampling so it doesnt get blurry

const float dither[16] = float[16]( // 4×4 ps1 ordered dither matrix, it hold the offset values that gets applied to each pixel depending on its screen postion 
	-4.0,  0.0, -3.0,  1.0,
	 2.0, -2.0,  3.0, -1.0,
	-3.0,  1.0, -4.0,  0.0, 
	 3.0, -1.0,  2.0, -2.0
);


void fragment() { // fragment func lets you manipulation each pixel 
	vec3 screen_color = texture(screen_tex, UV).rgb; // get the rgb color of the pixel
	
    // this gets where the pixel sit in the dither matrix
	int x = int(FRAGCOORD.x) % 4; // FRAGCOORD is the pixel's actual 2D screen postion and % get it to 0 to 3 range 
	int y = int(FRAGCOORD.y) % 4;
	int index = y * 4 + x; // converts 2D coordinates into a flat array index
	
	float dither_offset = (dither[index] / 8.0); // gets the offset
	
	vec3 quantized_color = floor((screen_color * 255.0) / 8.0 + dither_offset) /31.0; // quantizes 8bit color with dither offset to a 5bit color 
    // (screen_color * 255.0) screen color is in 0 to 1 range * 255 changes it into 0-255 range
    // (screen_color * 255.0) / 8.0 divides it to have only 32 colors or 5 bit channel (to nearest integer)
    // + dither_offset adds noise more on this later
    // floor() snaps it to nearest no
    // /31.0 as the color cannot be in 0 to 31 range so this changes it into 0-1 range 
	
	COLOR = vec4(quantized_color, 1); // applies the color and 1 is the alpha value
}
```

what is dithering?, it is a technique which involves intentional application of noise in images, video or even audio, in image it is used to simulate the sense of having more colors then there actually is (the eyes creates its own color), this is being used till now especially in mobile games and was used in ps1 game to hide this
<br>well why do we use dither isn't 32768 a lot a color no, I thought that but I was wrong even with these many color you could see color banding (not a smooth gradent between colors)

<img width="418" height="303" alt="Colour_banding_example01" src="https://github.com/user-attachments/assets/8123fd45-b9db-41b4-b00d-ace11ce7fe3f" />

Also if you have a old monitor the dithering effect looks so good, try it, 
<br>also you could probably use a crt filter, it would make it cooler and would really give that retro feel 

## Jitter effect
In my opinion this effect characterizes PS1 games the best, the jitter effect
<br>So what is it?, its the effect when polygons snap to pixels at the rasterization stage of 3D rendering and give the polygon a jitter effect
<br>Why does this happen?, The ps1 hardware rasterizer was unable to render polygons at a sub pixel level due to lack of precision to calculate positions between pixels so it only worked with integers and rounder off the decimals, which caused them to appear snapping at lower resolution (if only it could render at higher resolution it would not be that evident), modern gpus can accurately calculate to sub pixel level and can render at higer res 

### Recreate
Ok so, for this you have to add material override for every material you have on a model and for every model as we have to individually edit the models vertices
<br> you could use a script to do this for you at runtime if you have a lot of models which would be easier, or using a editor tool

The material override will be a shader material, you will see after this the materials are gone form you model cause the material is overridden with the shader material

#### code
```
shader_type spatial;
render_mode blend_mix,
cull_back,
depth_prepass_alpha,
shadows_disabled,
specular_disabled, // these just strips the modern rendering features
vertex_lighting; 

uniform sampler2D base_tex: source_color ,filter_nearest; // Its a parameter in the shader for the material base color
uniform vec2 texture_tile = vec2(1,1); // tiles the texture
uniform vec2 texture_offset = vec2(0,0); // offset if needed

uniform bool snap_enabled = true; // should have jitter effect?
uniform float snap_res : hint_range(60.0, 480.0, 1) = 128; //smaller value more jitter
                                                           // fake resolution for vertex positions

void vertex() { //runs for every vertex in a mesh and lets you manipulate it
// we are reversing the modern rendering pipeline so we can inject our code into it
	vec4 view_space_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0); // object space to view space
	vec4 clip_space_pos = PROJECTION_MATRIX * view_space_pos; // view space to clip space
	
	if (snap_enabled){
		vec2 ndc = clip_space_pos.xy / clip_space_pos.w;
		ndc = round(ndc * snap_res) / snap_res;
		clip_space_pos.xy = ndc * clip_space_pos.w;
	}
	POSITION = clip_space_pos;
    // clip_space_pos.xy / clip_space_pos.w; converts it into NDC(Normalized Device Coordinates, the –1 to +1 screen space) by dividing it by the forth direction of the modern clip space w
    // round(ndc * snap_res) / snap_res; locks the vertex to one of the point in the fake res across the screen
    // ndc * clip_space_pos.w; converts back to clip space
    // POSITION = clip_space_pos; sets the postion
}

void fragment() { // in fragment shader we are only applying back the textures
	vec4 base = texture(base_tex,UV * texture_tile + texture_offset);
	ALBEDO = base.rgb;
	ALPHA = base.a;
}
```
[check this out](https://www.youtube.com/watch?v=y84bG19sg6U) for better explanation on the ndc part

tweak and experiment with the shader paramaters to fit with what you want, apply the base texture there so the texture is visible 

## more you could add
Affine texture mapping - gives disported texture mapping, but most of the game tried to hide this using vertex color rather than textures, having high density models, fixed camera angles

<img width="960" height="404" alt="Perspective_correct_texture_mapping svg" src="https://github.com/user-attachments/assets/679646bc-7dd3-44ea-8da2-f855bdc00ed9" />

## fun facts
capcom use to have their resident evil games with fixed camera not just because of technical limitations but also as they wanted to have prerendered background for immersion and have cinematography that changes the mood
<br>these game use to have only one light source at a time and derived most of the light from AO maps (prebaked lighting from real world places)

## Resources
https://www.hawkjames.com/indiedev/update/2022/06/02/rendering-ps1.html
<br>https://www.youtube.com/watch?v=y84bG19sg6U
<br>https://www.youtube.com/watch?v=VkmTr5WBjF8&t=718s
<br>Images from [wikipedia](https://www.wikipedia.org/)

# bonus 
This part contains an animation trick used mainly in 2D looking 3D animations like used in Spider-Man: Across the Spider-Verse which is Animating on 3s or 2s which is conceptually similar to stop motion animation, and to some extent you can use this in your retro game for a unique animation style
<br>so what does this mean, for example you are animating on 3s it just means the next animation frame will be after 3 frames of that constant frame, so no in-betweens or transitions frame
<br>2s - 2 constant frame
<br>3s - 3 constant frame and so on

simple steps to make any animation into a 3 step animation 
1. Select an animation, Which can be done by selecting the fbx model which has the animation
2. Remove every 2 keyframes after one (I have a custom script which does the whole process)
3. Then select all the left keyframes with A key then press T key and set the interpolation to constant
<br>And yeah that's it, you have a 3 step animation or 3s 

##### here is a simple py script for blender which does the process for you
```
import bpy

step = 2 ## determines the step 

obj = bpy.context.active_object

if obj and obj.animation_data and obj.animation_data.action:

    action = obj.animation_data.action

    for fcurve in action.fcurves:

        keys = fcurve.keyframe_points

        # remove keys except every nth
        for i in reversed(range(len(keys))):
            if i % step != 0:
                keys.remove(keys[i])

        # set constant interpolation
        for kp in keys:
            kp.interpolation = 'CONSTANT'

    # refresh UI
    for area in bpy.context.screen.areas:
        if area.type in {'DOPESHEET_EDITOR', 'GRAPH_EDITOR'}:
            area.tag_redraw()

else:
    print("Select an object with animation.")
```
