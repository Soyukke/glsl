using GLFW
using ModernGL
using Dates

function read_shader(;shaderID::GLuint, filename::String)
    open(filename, "r") do f
        lines = readlines(f)
        shadercode = join(lines, "\n")
        len_code = Ref{GLint}(length(shadercode))
        ptrStr = Ptr{GLchar}[pointer(Vector{GLchar}(shadercode))]
        count::GLsizei = 1
        glShaderSource(shaderID, count, ptrStr, len_code)
    end
end

function compile_shader(shaderID)
    compiled = GLint[0]
    glCompileShader(shaderID)
    glGetShaderiv(shaderID, GL_COMPILE_STATUS, compiled)
    if first(compiled) == GL_FALSE
        println("GLSL コンパイルエラー")
        max_length = GLint[0]
        glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, max_length)
        if first(max_length) > 0
            buffer = zeros(GLchar, first(max_length))
            bufsize = GLsizei[0]
            glGetShaderInfoLog(shaderID, first(max_length), bufsize, buffer)
            print(String(Vector{Char}(buffer)))
        end
    else
        println("コンパイルOK")
    end
end

function main()
    cd(@__DIR__)
    GLFW.Init() || return
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 4)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 5)
    width, height = 512, 512
    window = GLFW.CreateWindow(width, height, "GLFW.jl")
    GLFW.MakeContextCurrent(window)
    # シェーダーファイル
    fn_frag = "shader.frag"
    fn_vert = "shader.vert"
    # シェーダーオブジェクト
    vert_obj = glCreateShader(GL_VERTEX_SHADER)
    frag_obj = glCreateShader(GL_FRAGMENT_SHADER)
    # プログラム読み込み
    read_shader(shaderID=vert_obj, filename=fn_vert)
    read_shader(shaderID=frag_obj, filename=fn_frag)
    # コンパイル
    compile_shader(vert_obj)
    compile_shader(frag_obj)
    # プログラムオブジェクト
    shader = glCreateProgram()
    # アタッチ
    glAttachShader(shader, vert_obj)
    glAttachShader(shader, frag_obj)
    # 変数バインド
    glBindFragDataLocation(shader, 0, "color")
    # リンク
    glLinkProgram(shader)
    # シェーダーオブジェクトの削除
    glDeleteShader(vert_obj)
    glDeleteShader(frag_obj)
    # リンクが成功したかどうか
    linked = GLint[0]
    glGetProgramiv(shader, GL_LINK_STATUS, linked)
    if first(linked) == GL_FALSE
        println("プログラムリンク失敗")
        return
    else
        println("linked $(linked)")
        println("プログラムリンクOK")
    end
    # VAO
    vao = GLuint[0]
    glGenVertexArrays(1, vao)
    glBindVertexArray(first(vao))

    # VBO
    vbo = GLuint[0]
    # 全頂点
    vertices = Vector{GLfloat}()
    for x in -width:width, y in -height:height
        push!(vertices, [x/width, y/height, 0]...)
    end
    glGenBuffers(1, vbo)
    glBindBuffer(GL_ARRAY_BUFFER, first(vbo))
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    # position in shader.vert
    position = glGetAttribLocation(shader, "position")
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
    glBindBuffer(GL_ARRAY_BUFFER, first(vbo))
    glEnableVertexAttribArray(position)
    # uniform parameters
    mouse = [0, 0]
    time_start = time()
    time_count = time_start
    width = GLfloat(width)
    height = GLfloat(height)
    while !GLFW.WindowShouldClose(window)
        # uniform
        time_count = time() - time_start
        # GetCursorPosは左上が (x, y) = (1, 1)なので，yを反転してシフトして右下を0, 0とする
        # window外もあるので0 - width - 1にする
        x, y = GLFW.GetCursorPos(window) 
        x = GLfloat(x - 1)              # x [1, width]  -> [0, width-1]
        y = GLfloat(height - y)         # y [1, height] -> [0, height-1]
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glUseProgram(shader)
        # Uniform ループで呼び出し続けないといけないらしい resolutionを外側に書いたらだめだった
        glUniform2f(glGetUniformLocation(shader, "resolution"), width, height)
        glUniform1f(glGetUniformLocation(shader, "time"), time_count)
        glUniform2f(glGetUniformLocation(shader, "mouse"), x, y)
        # 描画
        glDrawArrays(GL_POINTS, 0, length(vertices)/3)
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end
    GLFW.DestroyWindow(window)
end

main()