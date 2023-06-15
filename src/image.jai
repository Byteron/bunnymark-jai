
Texture :: GLuint;

load_texture :: (path: string) -> Texture, bool {
	id: u32 = 0;
    glGenTextures(1, *id);
    glBindTexture(GL_TEXTURE_2D, id);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    width, height, nr_channels : s32 = 0;
    full_path := tprint("%/%", assets_folder, path);

    // stbi_set_flip_vertically_on_load(true);
    data := stbi_load(to_c_string(full_path), *width, *height, *nr_channels, 4);
    defer stbi_image_free(data);

    if data != null {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    else
    {
        print("Failed to load texture at %\n", full_path);
        return 0, false;
    }

    return id, true;
}