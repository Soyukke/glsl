using GLFW
using ModernGL

cd(@__DIR__)

# 参考
# https://codelabo.com/633/

# Juliaにおけるキーワード引数はセミコロンの後に定義する
# Pythonではデフォルトでキーワード引数になっている
function readShaderSource(;shaderID::GLuint, filename::String)
    open(filename, "r") do f
        lines = readlines(f)
        # ソースコード
        shadercode = join(lines, "\n")
        # ソースコードの文字数
        len_code = Ref{GLint}(length(shadercode))
        ptrStr = Ptr{GLchar}[pointer(Vector{GLchar}(shadercode))]
        count::GLsizei = 1
        glShaderSource(shaderID, count, ptrStr, len_code)
    end
end

function compile_shader(shaderID)
    # コンパイル
    # 参照渡し
    # compiled = Ref{GLint}(1)
    # 配列で渡してもOK
    compiled = GLint[0]
    glCompileShader(shaderID)
    glGetShaderiv(shaderID, GL_COMPILE_STATUS, compiled)
    # GL_FALSE:0, GL_TRUE:1
    if first(compiled) == GL_FALSE
        println("GLSL コンパイルエラー")
        max_length = GLint[0]
        # ログの文字列の長さ
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
    GLFW.Init() || return
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 4)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 5)
    window = GLFW.CreateWindow(512, 512, "GLFW.jl")
    # Windowのcontextを作成
    GLFW.MakeContextCurrent(window)
    # シェーダーファイル
    fn_frag = "shader.frag"
    fn_vert = "shader.vert"
    # シェーダーオブジェクト
    vert_obj = glCreateShader(GL_VERTEX_SHADER)
    frag_obj = glCreateShader(GL_FRAGMENT_SHADER)
    # プログラム読み込み
    readShaderSource(shaderID=vert_obj, filename=fn_vert)
    readShaderSource(shaderID=frag_obj, filename=fn_frag)
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

    linked = GLint[0]
    glGetProgramiv(shader, GL_LINK_STATUS, linked)
    if first(linked) == GL_FALSE
        println("プログラムのリンク失敗")
        return
    else
        println("linked $(linked)")
        println("プログラムリンクOK")
    end

    vao = GLuint[0]
    glGenVertexArrays(1, vao)
    glBindVertexArray(first(vao))

    vbo = GLuint[0]
    vertices = GLfloat[-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 0.0, 1.0, 0.0]
    glGenBuffers(1, vbo)
    println("vbo: $(first(vbo))")
    glBindBuffer(GL_ARRAY_BUFFER, first(vbo))
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    # glBindBuffer(GL_ARRAY_BUFFER, 0)
    println("vbo: $vbo")

    # Vertex .vertのattributeで定義されているposition
    position = glGetAttribLocation(shader, "position")
    println("position: $(position)")
    # 頂点の設定
    # Ptr{GLfloat}[0]
    # 頂点の設定
    # glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 0, Ptr{GLfloat}[0])
    # 頂点データの場所 index 0から3要素ずつ, GL_FLOAT型, 正規化しない, stride=0 byteでデータを連続的に読む．
    # Ptr{GLfloat}[0]から読む
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
    # 変数の有効化
    # 頂点描画
    glBindBuffer(GL_ARRAY_BUFFER, first(vbo))
    glEnableVertexAttribArray(position)

    iteration = 0
    n = 3000
    while !GLFW.WindowShouldClose(window)
        # 画面をクリア
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)


        # Shader
        glUseProgram(shader)
        # glClearColor(0.2, 0.2, iteration/n, 1)

        # 三角形, vertex index = [0, 1, 2]
        # glDrawArrays(GL_TRIANGLES, 0, length(vertices)/3)
        # glDrawArrays(GL_POINTS, 0, length(vertices)/3)
        glDrawArrays(GL_LINE_LOOP, 0, length(vertices)/3)

        # バッファを入れ替える
        GLFW.SwapBuffers(window)
        # 描画
        GLFW.PollEvents()
        iteration = mod(iteration+1, n)

    end


    # バインドおわり
    # glBindBuffer(GL_ARRAY_BUFFER, first(buffer_id))
    # glDisableVertexAttribArray(position)
    glDisableVertexAttribArray(position)
    GLFW.DestroyWindow(window)
end

main()