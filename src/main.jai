#import "Basic";
#import "System";
#import "String";
#import "SDL";
#import "GL";
#import "Math";
#import "stb_image";
#import "Random";

#load "image.jai";
#load "render.jai";

assets_folder: string;

window_width := 1042;
window_height := 768;

main :: () {
    path := path_strip_filename(get_path_of_running_executable());
    assets_folder = join(path, "assets");

	SDL_Init(SDL_INIT_VIDEO);
	defer SDL_Quit();
    
	window := SDL_CreateWindow("Jai Bunnymark", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx window_width, xx window_height, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
	defer SDL_DestroyWindow(window);
	
    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }  

    gl_load(*gl, SDL_GL_GetProcAddress);
    using gl;

    print ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print ("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    if !init_render() {
        return;
    }

    texture, success := load_texture("images/bunny.png");
    if !success {
        return;
    }

    bunnies := 1;

    positions: [..]Vector2;
    velocities: [..]Vector2;

    for 1..bunnies {
        array_add(*positions, .{50, 50});
        array_add(*velocities, .{random_get_within_range(-200, 200), random_get_within_range(-200, 200)});
    }

    time: float;
    delta: float;

    exit := false;
    while !exit {
        event : SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT;
                    exit = true;
                case SDL_KEYUP;
                    if event.key.keysym.sym == SDLK_ESCAPE exit = true;
                case SDL_WINDOWEVENT;
                    if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
                        window_width = event.window.data1;
                        window_height = event.window.data2;
                    }
            }
        }

        new_time: float = xx get_time();
        delta := new_time - time;
        time = new_time;

        glViewport(0, 0, xx window_width, xx window_height);
        glClearColor(0.2, 0.2, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        for 0..bunnies-1 {
            position := positions[it];
            velocity := velocities[it];

            position += velocity * delta;

            if position.x < 0 || position.x > xx window_width velocity.x = -velocity.x;
            if position.y < 0 || position.y > xx window_height velocity.y = -velocity.y;

            positions[it] = position;
            velocities[it] = velocity;
            
            // draw_texture(texture, position, .{32, 32});
        }
        
        draw_textures(texture, positions, .{32, 32});
        check_gl_error();

        // print("FPS %\n", 1.0 / delta);

        SDL_GL_SwapWindow(window);
    }
}
