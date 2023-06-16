MAX_INSTANCES :: 100000;

VERTICES :: Vertex.[
	.{.{0.5, 0.5, 0.0}, .{1.0, 1.0}}, // top right
	.{.{0.5, -0.5, 0.0}, .{1.0, 0.0}}, // bottom right
	.{.{-0.5, -0.5, 0.0}, .{0.0, 0.0}}, // bottom left
	.{.{-0.5, 0.5, 0.0}, .{0.0, 1.0}},  // top left
];

INDICES :: u32.[
	0, 1, 3,
	1, 2, 3,
];

PROGRAM: GLuint = 0;
VBO, VAO, EBO : GLuint = 0;

PROGRAM_INSTANCED: GLuint = 0;
VAO_INSTANCED, VBO_INSTANCED : GLuint = 0;


Vertex :: struct {
	position: Vector3;
	uv: Vector2;
}

check_gl_error :: () {
    error := glGetError();
    while (error != GL_NO_ERROR) {
        print("OpenGL Error: %\n", error);

        // Check for more errors
        error = glGetError();
    }
}

create_shader_program :: (vertex_source: string, fragment_source: string) -> GLuint, bool {

	check_compile_errors :: (shader: GLuint) -> bool, string {
		success: s32;
		glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
		if !success {
			info_len: s32;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast(*u8) alloc(info_len, temp);
			glGetShaderInfoLog(shader, xx info_len, xx *info_len, info_data);
			result: string;
			result.data = info_data;
			result.count = info_len;

			return false, result;
		}

		return true, "";
	}

	check_link_errors :: (program: GLuint) -> bool, string {
		success: s32;
		glGetProgramiv(program, GL_LINK_STATUS, *success);
		if !success {
			info_len: s32;
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast(*u8) alloc(info_len, temp);
			glGetProgramInfoLog(program, xx info_len, xx *info_len, info_data);
			result: string;
			result.data = info_data;
			result.count = info_len;

			return false, result;
		}

		return true, "";
	}

	vs := glCreateShader(GL_VERTEX_SHADER);
	defer glDeleteShader(vs);
	glShaderSource(vs, 1, *vertex_source.data, null);
	glCompileShader(vs);
	ok, info_log := check_compile_errors(vs);
	if !ok {
		log_error("Could not compile vertex shader %", info_log);
		return 0, false;
	}

	fs := glCreateShader(GL_FRAGMENT_SHADER);
	defer glDeleteShader(fs);
	glShaderSource(fs, 1, *fragment_source.data, null);
	glCompileShader(fs);
	ok, info_log = check_compile_errors(fs);
	if !ok {
		log_error("Could not compile fragment shader %", info_log);
		return 0, false;
	}

	result := glCreateProgram();
	glAttachShader(result, vs);
	glAttachShader(result, fs);
	glLinkProgram(result);
	ok, info_log = check_link_errors(result);
	if !ok {
		log_error("Could not link shader program %", info_log);
		glDeleteProgram(result);
		return 0, false;
	}

	return result, true;
}

init_render :: () -> bool {
	ok: bool;

	// NORMAL

	PROGRAM, ok = create_shader_program(VERTEX_SHADER, FRAGMENT_SHADER);
	if !ok return false;

	glGenVertexArrays(1, *VAO);
	glGenBuffers(1, *VBO);
	glGenBuffers(1, *EBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * 4, cast(*void)VERTICES.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), null);
    glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void)(3 * size_of(float)));
    glEnableVertexAttribArray(1);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 6, cast(*void)INDICES.data, GL_STATIC_DRAW);

	glBindVertexArray(0);

	// INSTANCED 

	PROGRAM_INSTANCED, ok = create_shader_program(VERTEX_SHADER_INSTANCED, FRAGMENT_SHADER);
	if !ok return false;

	glGenVertexArrays(1, *VAO_INSTANCED);
	glGenBuffers(1, *VBO_INSTANCED);

	glBindVertexArray(VAO_INSTANCED);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * 4, cast(*void)VERTICES.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), null);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void)(3 * size_of(float)));
	glEnableVertexAttribArray(1);

	// Bind and set instance buffer data (empty for now, you will update this every frame or whenever instance data changes)
	glBindBuffer(GL_ARRAY_BUFFER, VBO_INSTANCED);
	glBufferData(GL_ARRAY_BUFFER, size_of(Matrix4) * MAX_INSTANCES, null, GL_DYNAMIC_DRAW);  // Reserve space for MAX_INSTANCES

	// Instance attribute pointers (assuming Matrix4 is made up of 4 Vector4's)
	for i: 0..3 {
		glVertexAttribPointer(xx (2 + i), 4, GL_FLOAT, GL_FALSE, size_of(Matrix4), cast(*void) (i * size_of(Vector4)));
		glEnableVertexAttribArray(xx (2 + i));
		glVertexAttribDivisor(xx (2 + i), 1);  // this makes it instanced
	}

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 6, cast(*void)INDICES.data, GL_STATIC_DRAW);

	glBindVertexArray(0);

	// GENERAL STUFF

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	return true;
}

draw_texture :: (texture: Texture, transform: Matrix4) {
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture);
	
	glBindVertexArray(VAO);

	glUseProgram(PROGRAM);
    glUniform1i(glGetUniformLocation (PROGRAM, "texture0"), 0);

	transform_loc := glGetUniformLocation(PROGRAM, "transform");
	glUniformMatrix4fv(transform_loc, 1, GL_TRUE, *transform.coef[0][0]);

	projection := orthographic_projection_matrix(0, xx window_width, xx window_height, 0, 0, 1);
	proj_loc := glGetUniformLocation(PROGRAM, "projection");
	glUniformMatrix4fv(proj_loc, 1, GL_TRUE, *projection.coef[0][0]);

	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

	glBindVertexArray(0);
}

draw_textures :: (texture: Texture, transforms: [..]Matrix4) {
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture);

	glBindBuffer(GL_ARRAY_BUFFER, VBO_INSTANCED);
	glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Matrix4) * transforms.count, xx transforms.data);
	
	glBindVertexArray(VAO_INSTANCED);
	
	glUseProgram(PROGRAM_INSTANCED);
    glUniform1i(glGetUniformLocation (PROGRAM_INSTANCED, "texture0"), 0);

	projection := orthographic_projection_matrix(0, xx window_width, xx window_height, 0, 0, 1);
	proj_loc := glGetUniformLocation(PROGRAM_INSTANCED, "projection");
	glUniformMatrix4fv(proj_loc, 1, GL_TRUE, *projection.coef[0][0]);

	glDrawElementsInstanced(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null, xx transforms.count);

	glBindVertexArray(0);
}

VERTEX_SHADER :: #string GLSL
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aTexCoord;

out vec2 TexCoord;

uniform mat4 transform;
uniform mat4 projection;


void main() {
	TexCoord = aTexCoord;
	gl_Position = projection * transform * vec4(aPosition, 1.0);
}
GLSL

VERTEX_SHADER_INSTANCED :: #string GLSL
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in mat4 aInstanceTransform;

out vec2 TexCoord;

uniform mat4 projection;

void main() {
	TexCoord = aTexCoord;
	mat4 transposedTransform = mat4(
        aInstanceTransform[0][0], aInstanceTransform[1][0], aInstanceTransform[2][0], aInstanceTransform[3][0],
        aInstanceTransform[0][1], aInstanceTransform[1][1], aInstanceTransform[2][1], aInstanceTransform[3][1],
        aInstanceTransform[0][2], aInstanceTransform[1][2], aInstanceTransform[2][2], aInstanceTransform[3][2],
        aInstanceTransform[0][3], aInstanceTransform[1][3], aInstanceTransform[2][3], aInstanceTransform[3][3]
    );

	gl_Position = projection * transposedTransform * vec4(aPosition, 1.0);
}
GLSL

FRAGMENT_SHADER :: #string GLSL
#version 330 core
out vec4 FragColor;
  
in vec2 TexCoord;

uniform sampler2D texture0;

void main()
{
    FragColor = texture(texture0, TexCoord);
}
GLSL